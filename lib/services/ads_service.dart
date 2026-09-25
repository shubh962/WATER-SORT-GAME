import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:water_sort/config/app_config.dart';
import 'package:water_sort/services/app_state.dart';
import 'package:water_sort/services/interstitial_policy.dart';
import 'package:water_sort/services/telemetry.dart';

class RewardedResult {
  const RewardedResult(this.rewarded, [this.reason]);
  final bool rewarded;
  final String? reason; // 'unavailable' | 'dismissed' | 'failed'
}

/// AdMob: consent (UMP), banner ids, preloaded interstitial + rewarded ads with
/// retry/backoff, and the frequency policy.
class AdsService extends ChangeNotifier {
  AdsService(this._state, {InterstitialPolicy? policy}) : _policy = policy ?? InterstitialPolicy();

  final AppState _state;
  final InterstitialPolicy _policy;

  /// True while a full-screen ad is on screen (the game pauses on this).
  final ValueNotifier<bool> adShowing = ValueNotifier<bool>(false);

  bool _started = false;
  bool _canRequest = false;
  bool _sdkReady = false;
  bool privacyOptionsRequired = false;

  InterstitialAd? _interstitial;
  bool _interLoading = false;
  int _interFails = 0;

  RewardedAd? _rewarded;
  bool _rewardLoading = false;
  int _rewardFails = 0;

  bool get ready => _canRequest && _sdkReady;

  Future<void> init() async {
    if (_started) return;
    _started = true;
    if (kIsWeb) return; // AdMob has no web support
    if (AdIds.realIdsMissing) {
      Telemetry.error(StateError('Release build without real AdMob ad unit IDs'), null, reason: 'ads');
      return;
    }
    if (kReleaseMode && AppConfig.useTestAds) {
      debugPrint('WARNING: release build is using TEST ads. Build with --dart-define=USE_TEST_ADS=false');
    }
    try {
      _canRequest = await _gatherConsent();
      privacyOptionsRequired = await _isPrivacyOptionsRequired();
      if (_canRequest) await _startSdk();
    } catch (e, s) {
      Telemetry.error(e, s, reason: 'ads.init');
    }
    notifyListeners();
  }

  // ---------- consent (Google UMP) ----------
  Future<bool> _gatherConsent() {
    final done = Completer<bool>();
    Future<void> finish() async {
      if (done.isCompleted) return;
      try {
        done.complete(await ConsentInformation.instance.canRequestAds());
      } catch (_) {
        done.complete(false);
      }
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null) debugPrint('UMP form error: ${error.message}');
          unawaited(finish());
        });
      },
      (FormError error) {
        debugPrint('UMP update error: ${error.message}');
        unawaited(finish()); // cached consent from an earlier session may still allow ads
      },
    );
    return done.future.timeout(const Duration(seconds: 45), onTimeout: () => false);
  }

  Future<bool> _isPrivacyOptionsRequired() async {
    final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  /// Settings screen entry point ("Ad privacy settings").
  Future<void> showPrivacyOptions() async {
    final done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) debugPrint('UMP options error: ${error.message}');
      if (!done.isCompleted) done.complete();
    });
    await done.future.timeout(const Duration(minutes: 2), onTimeout: () {});
    // The user may have changed consent: start the SDK if it just became allowed.
    _canRequest = await ConsentInformation.instance.canRequestAds();
    if (_canRequest && !_sdkReady) await _startSdk();
    notifyListeners();
  }

  Future<void> _startSdk() async {
    await MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
      testDeviceIds: AppConfig.testDeviceIds,
      maxAdContentRating: MaxAdContentRating.pg,
    ));
    await MobileAds.instance.initialize();
    _sdkReady = true;
    _loadInterstitial();
    _loadRewarded();
  }

  void _retry(VoidCallback load, int fails) {
    final seconds = math.min(60, 1 << math.min(fails, 6)); // 2,4,8,...60
    Timer(Duration(seconds: seconds), load);
  }

  // ---------- interstitial ----------
  void _loadInterstitial() {
    if (!ready || _interLoading || _interstitial != null || _state.adsFree) return;
    _interLoading = true;
    InterstitialAd.load(
      adUnitId: AdIds.units.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitial = ad;
          _interLoading = false;
          _interFails = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interLoading = false;
          _interFails++;
          debugPrint('Interstitial failed: ${error.message}');
          _retry(_loadInterstitial, _interFails);
        },
      ),
    );
  }

  /// Called by the game at the break between levels. Returns true if an ad was shown.
  Future<bool> maybeShowInterstitial({required int level}) async {
    final now = DateTime.now();
    if (!_policy.isDue(level: level, now: now, adsFree: _state.adsFree)) return false;
    final ad = _interstitial;
    if (ad == null || !ready) {
      _loadInterstitial();
      return false; // never make the player wait for an ad
    }
    _interstitial = null;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (InterstitialAd a) => adShowing.value = true,
      onAdDismissedFullScreenContent: (InterstitialAd a) {
        a.dispose();
        adShowing.value = false;
        _loadInterstitial();
        if (!done.isCompleted) done.complete(true);
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd a, AdError e) {
        a.dispose();
        adShowing.value = false;
        _loadInterstitial();
        if (!done.isCompleted) done.complete(false);
      },
    );
    _policy.markShown(now);
    Telemetry.event('ad_interstitial_show', <String, Object?>{'level': level});
    await ad.show();
    return done.future.timeout(const Duration(minutes: 3), onTimeout: () {
      adShowing.value = false;
      return false;
    });
  }

  // ---------- rewarded ----------
  void _loadRewarded() {
    if (!ready || _rewardLoading || _rewarded != null) return;
    _rewardLoading = true;
    RewardedAd.load(
      adUnitId: AdIds.units.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewarded = ad;
          _rewardLoading = false;
          _rewardFails = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardLoading = false;
          _rewardFails++;
          debugPrint('Rewarded failed: ${error.message}');
          _retry(_loadRewarded, _rewardFails);
        },
      ),
    );
  }

  Future<RewardedResult> showRewarded({required String placement}) async {
    if (!ready) return const RewardedResult(false, 'unavailable');
    if (_rewarded == null) {
      _loadRewarded();
      for (var i = 0; i < 20 && _rewarded == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200)); // wait up to 4 s
      }
    }
    final ad = _rewarded;
    if (ad == null) return const RewardedResult(false, 'unavailable');
    _rewarded = null;

    var earned = false;
    final done = Completer<RewardedResult>();
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (RewardedAd a) => adShowing.value = true,
      onAdDismissedFullScreenContent: (RewardedAd a) {
        a.dispose();
        adShowing.value = false;
        _loadRewarded();
        if (!done.isCompleted) done.complete(RewardedResult(earned, earned ? null : 'dismissed'));
      },
      onAdFailedToShowFullScreenContent: (RewardedAd a, AdError e) {
        a.dispose();
        adShowing.value = false;
        _loadRewarded();
        if (!done.isCompleted) done.complete(const RewardedResult(false, 'failed'));
      },
    );
    Telemetry.event('ad_rewarded_show', <String, Object?>{'placement': placement});
    await ad.show(onUserEarnedReward: (AdWithoutView a, RewardItem reward) {
      earned = true;
    });
    return done.future.timeout(const Duration(minutes: 5), onTimeout: () {
      adShowing.value = false;
      return RewardedResult(earned, earned ? null : 'failed');
    });
  }
}
