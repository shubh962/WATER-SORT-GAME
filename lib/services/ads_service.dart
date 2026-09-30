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

/// AdMob service for consent, SDK startup, preloading and full-screen ads.
///
/// Banner loading is intentionally owned by BannerAdView because banners need
/// a real widget width. This service only exposes the SDK/consent readiness
/// that the banner waits for.
class AdsService extends ChangeNotifier {
  AdsService(this._state, {InterstitialPolicy? policy})
      : _policy = policy ?? InterstitialPolicy();

  final AppState _state;
  final InterstitialPolicy _policy;

  /// True while a full-screen ad is on screen (the game pauses on this).
  final ValueNotifier<bool> adShowing = ValueNotifier<bool>(false);

  bool _started = false;
  bool _canRequest = false;
  bool _sdkReady = false;
  bool _disposed = false;
  bool privacyOptionsRequired = false;

  InterstitialAd? _interstitial;
  bool _interLoading = false;
  int _interFails = 0;
  Timer? _interRetry;

  RewardedAd? _rewarded;
  bool _rewardLoading = false;
  int _rewardFails = 0;
  Timer? _rewardRetry;

  bool get ready => !_disposed && _canRequest && _sdkReady;

  Future<void> init() async {
    if (_started || _disposed) return;
    _started = true;

    if (kIsWeb) return;

    if (AdIds.realIdsMissing) {
      Telemetry.error(
        StateError('Release build without real AdMob ad unit IDs'),
        null,
        reason: 'ads',
      );
      return;
    }

    if (kReleaseMode && AppConfig.useTestAds) {
      debugPrint(
        'WARNING: release build is using TEST ads. '
        'Build with --dart-define=USE_TEST_ADS=false',
      );
    }

    try {
      _canRequest = await _gatherConsent();
      privacyOptionsRequired = await _isPrivacyOptionsRequired();
      if (_canRequest && !_disposed) {
        await _startSdk();
      }
    } catch (e, s) {
      Telemetry.error(e, s, reason: 'ads.init');
    }

    if (!_disposed) notifyListeners();
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
          if (error != null) {
            debugPrint('UMP form error: ${error.message}');
          }
          unawaited(finish());
        });
      },
      (FormError error) {
        debugPrint('UMP update error: ${error.message}');
        // A cached consent state can still allow ads.
        unawaited(finish());
      },
    );

    return done.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () => false,
    );
  }

  Future<bool> _isPrivacyOptionsRequired() async {
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  /// Settings screen entry point ("Ad privacy settings").
  Future<void> showPrivacyOptions() async {
    if (kIsWeb || _disposed) return;

    final done = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) {
        debugPrint('UMP options error: ${error.message}');
      }
      if (!done.isCompleted) done.complete();
    });

    await done.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {},
    );

    if (_disposed) return;

    _canRequest = await ConsentInformation.instance.canRequestAds();
    if (_canRequest && !_sdkReady) {
      await _startSdk();
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> _startSdk() async {
    if (_sdkReady || _disposed) return;

    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: AppConfig.testDeviceIds,
        maxAdContentRating: MaxAdContentRating.pg,
      ),
    );

    await MobileAds.instance.initialize();

    if (_disposed) return;
    _sdkReady = true;

    // Preload full-screen formats. BannerAdView separately loads the banner
    // once it knows its actual available width.
    _loadInterstitial();
    _loadRewarded();
  }

  Duration _retryDelay(int failures) {
    // Controlled backoff: 2, 4, 8, 16, 32, 60 seconds.
    // Do not hammer AdMob after a no-fill/network failure.
    final seconds = math.min(60, 1 << math.min(failures, 5));
    return Duration(seconds: seconds);
  }

  // ---------- interstitial ----------
  void _scheduleInterstitialRetry() {
    _interRetry?.cancel();
    if (!ready || _state.adsFree || _disposed) return;

    final delay = _retryDelay(_interFails);
    _interRetry = Timer(delay, () {
      _interRetry = null;
      _loadInterstitial();
    });
  }

  void _loadInterstitial() {
    if (!ready ||
        _interLoading ||
        _interstitial != null ||
        _state.adsFree ||
        _disposed) {
      return;
    }

    _interRetry?.cancel();
    _interRetry = null;
    _interLoading = true;

    InterstitialAd.load(
      adUnitId: AdIds.units.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          if (_disposed || _state.adsFree) {
            ad.dispose();
            _interLoading = false;
            return;
          }
          _interstitial = ad;
          _interLoading = false;
          _interFails = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interLoading = false;
          _interstitial = null;
          _interFails++;
          debugPrint(
            'Interstitial failed: ${error.domain} / ${error.code} / ${error.message}',
          );
          debugPrint('Interstitial responseInfo=${error.responseInfo}');
          _scheduleInterstitialRetry();
        },
      ),
    );
  }

  /// Called by the game at the break between levels.
  /// Returns true if an ad was shown.
  Future<bool> maybeShowInterstitial({required int level}) async {
    if (_disposed) return false;

    final now = DateTime.now();
    if (!_policy.isDue(
      level: level,
      now: now,
      adsFree: _state.adsFree,
    )) {
      return false;
    }

    final ad = _interstitial;
    if (ad == null || !ready) {
      _loadInterstitial();
      return false; // Never make the player wait for an ad.
    }

    _interstitial = null;
    final done = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (InterstitialAd a) {
        adShowing.value = true;
      },
      onAdDismissedFullScreenContent: (InterstitialAd a) {
        a.dispose();
        adShowing.value = false;
        _loadInterstitial();
        if (!done.isCompleted) done.complete(true);
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd a, AdError e) {
        debugPrint('Interstitial failed to show: ${e.message}');
        a.dispose();
        adShowing.value = false;
        _loadInterstitial();
        if (!done.isCompleted) done.complete(false);
      },
    );

    _policy.markShown(now);
    Telemetry.event(
      'ad_interstitial_show',
      <String, Object?>{'level': level},
    );

    await ad.show();

    return done.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        adShowing.value = false;
        return false;
      },
    );
  }

  // ---------- rewarded ----------
  void _scheduleRewardedRetry() {
    _rewardRetry?.cancel();
    if (!ready || _disposed) return;

    final delay = _retryDelay(_rewardFails);
    _rewardRetry = Timer(delay, () {
      _rewardRetry = null;
      _loadRewarded();
    });
  }

  void _loadRewarded() {
    if (!ready || _rewardLoading || _rewarded != null || _disposed) {
      return;
    }

    _rewardRetry?.cancel();
    _rewardRetry = null;
    _rewardLoading = true;

    RewardedAd.load(
      adUnitId: AdIds.units.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (_disposed) {
            ad.dispose();
            _rewardLoading = false;
            return;
          }
          _rewarded = ad;
          _rewardLoading = false;
          _rewardFails = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardLoading = false;
          _rewarded = null;
          _rewardFails++;
          debugPrint(
            'Rewarded failed: ${error.domain} / ${error.code} / ${error.message}',
          );
          debugPrint('Rewarded responseInfo=${error.responseInfo}');
          _scheduleRewardedRetry();
        },
      ),
    );
  }

  Future<RewardedResult> showRewarded({required String placement}) async {
    if (!ready) {
      return const RewardedResult(false, 'unavailable');
    }

    if (_rewarded == null) {
      _loadRewarded();
      // Short wait only. The player should never be held for a long network
      // request just because a rewarded ad is not preloaded yet.
      for (var i = 0; i < 15 && _rewarded == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }

    final ad = _rewarded;
    if (ad == null) {
      return const RewardedResult(false, 'unavailable');
    }

    _rewarded = null;

    var earned = false;
    final done = Completer<RewardedResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (RewardedAd a) {
        adShowing.value = true;
      },
      onAdDismissedFullScreenContent: (RewardedAd a) {
        a.dispose();
        adShowing.value = false;
        _loadRewarded();
        if (!done.isCompleted) {
          done.complete(
            RewardedResult(
              earned,
              earned ? null : 'dismissed',
            ),
          );
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd a, AdError e) {
        debugPrint('Rewarded failed to show: ${e.message}');
        a.dispose();
        adShowing.value = false;
        _loadRewarded();
        if (!done.isCompleted) {
          done.complete(const RewardedResult(false, 'failed'));
        }
      },
    );

    Telemetry.event(
      'ad_rewarded_show',
      <String, Object?>{'placement': placement},
    );

    await ad.show(
      onUserEarnedReward: (AdWithoutView a, RewardItem reward) {
        earned = true;
      },
    );

    return done.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        adShowing.value = false;
        return RewardedResult(
          earned,
          earned ? null : 'failed',
        );
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _interRetry?.cancel();
    _rewardRetry?.cancel();
    _interRetry = null;
    _rewardRetry = null;
    _interstitial?.dispose();
    _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
    _interLoading = false;
    _rewardLoading = false;
    adShowing.dispose();
    super.dispose();
  }
}
