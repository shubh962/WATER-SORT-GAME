import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:water_sort/config/app_config.dart';
import 'package:water_sort/services/services.dart';
import 'package:water_sort/services/telemetry.dart';

/// Native AdMob anchored adaptive banner.
///
/// The widget owns the BannerAd lifecycle because it needs the real available
/// width from the Flutter layout. It does not block the game while an ad is
/// loading and uses controlled retry backoff after a failed request.
class BannerAdView extends StatefulWidget {
  const BannerAdView({super.key});

  @override
  State<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends State<BannerAdView> {
  BannerAd? _ad;
  AdSize? _size;
  bool _loaded = false;
  bool _loading = false;
  Timer? _retry;
  int _failures = 0;
  int _lastWidth = 0;

  @override
  void initState() {
    super.initState();
    Services.ads.addListener(_onChange);
    Services.state.addListener(_onChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_maybeLoad());
  }

  void _onChange() {
    if (!mounted) return;

    if (Services.state.adsFree) {
      _release();
      setState(() {});
      return;
    }

    if (Services.ads.ready) {
      unawaited(_maybeLoad());
    }
  }

  Future<void> _maybeLoad() async {
    if (!mounted ||
        _loading ||
        !Services.ads.ready ||
        Services.state.adsFree) {
      return;
    }

    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0) return;

    // If the available width changes (rotation, split-screen, etc.), discard
    // the old banner and request a correctly sized one.
    if (_ad != null && _lastWidth != 0 && _lastWidth != width) {
      _release();
    }

    if (_ad != null) return;

    _loading = true;
    _lastWidth = width;

    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);

    if (!mounted || Services.state.adsFree || !Services.ads.ready) {
      _loading = false;
      return;
    }

    if (size == null) {
      _loading = false;
      _scheduleRetry();
      return;
    }

    final ad = BannerAd(
      adUnitId: AdIds.units.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad loadedAd) {
          if (!mounted || Services.state.adsFree) {
            loadedAd.dispose();
            _loading = false;
            return;
          }

          final banner = loadedAd as BannerAd;
          _failures = 0;
          _retry?.cancel();
          _retry = null;
          _loading = false;

          setState(() {
            _ad = banner;
            _size = size;
            _loaded = true;
          });

          final response = banner.responseInfo;
          debugPrint(
            'Banner loaded. responseId=${response?.responseId} '
            'adapter=${response?.mediationAdapterClassName}',
          );
          Telemetry.event(
            'ad_banner_loaded',
            <String, Object?>{
              'adapter': response?.mediationAdapterClassName,
            },
          );
        },
        onAdFailedToLoad: (Ad failedAd, LoadAdError error) {
          failedAd.dispose();
          _ad = null;
          _size = null;
          _loaded = false;
          _loading = false;
          _failures++;

          debugPrint(
            'Banner failed: domain=${error.domain} '
            'code=${error.code} message=${error.message}',
          );
          debugPrint('Banner responseInfo=${error.responseInfo}');
          Telemetry.event(
            'ad_banner_failed',
            <String, Object?>{
              'domain': error.domain,
              'code': error.code,
            },
          );

          if (!mounted || Services.state.adsFree || !Services.ads.ready) {
            return;
          }

          if (mounted) setState(() {});
          _scheduleRetry();
        },
        onAdImpression: (Ad ad) {
          debugPrint('Banner impression recorded.');
          Telemetry.event(
            'ad_banner_impression',
            <String, Object?>{},
          );
        },
        onAdClicked: (Ad ad) {
          debugPrint('Banner clicked.');
        },
        onAdOpened: (Ad ad) {
          debugPrint('Banner opened.');
        },
        onAdClosed: (Ad ad) {
          debugPrint('Banner closed.');
        },
      ),
    );

    // Do not put the AdWidget in the tree until the SDK reports a successful
    // load. This avoids displaying an unloaded ad object.
    _ad = ad;
    _size = size;
    _loaded = false;
    _loading = true;

    if (mounted) setState(() {});

    await ad.load();
  }

  void _scheduleRetry() {
    _retry?.cancel();

    if (!mounted ||
        Services.state.adsFree ||
        !Services.ads.ready ||
        _loading ||
        _ad != null) {
      return;
    }

    // Controlled retry: 5, 15, 30, 60, then 120 seconds.
    // This helps recover from temporary network/no-fill conditions without
    // creating an aggressive request loop.
    const delays = <int>[5, 15, 30, 60, 120];
    final index = math.min(_failures - 1, delays.length - 1);
    final seconds = delays[math.max(0, index)];

    _retry = Timer(Duration(seconds: seconds), () {
      _retry = null;
      if (mounted) unawaited(_maybeLoad());
    });
  }

  void _release() {
    _retry?.cancel();
    _retry = null;

    final ad = _ad;
    _ad = null;
    _size = null;
    _loaded = false;
    _loading = false;
    _lastWidth = 0;

    ad?.dispose();
  }

  @override
  void dispose() {
    Services.ads.removeListener(_onChange);
    Services.state.removeListener(_onChange);
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final size = _size;

    if (Services.state.adsFree ||
        ad == null ||
        size == null ||
        !_loaded) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: size.height.toDouble(),
      child: Center(
        child: SizedBox(
          width: size.width.toDouble(),
          height: size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
