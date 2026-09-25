import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:water_sort/config/app_config.dart';
import 'package:water_sort/services/services.dart';

/// Anchored adaptive banner. Hidden for Remove Ads / PRO and while ads are not
/// allowed (consent). Loads lazily once the ads SDK is ready.
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
    } else {
      unawaited(_maybeLoad());
    }
  }

  Future<void> _maybeLoad() async {
    if (_ad != null || _loading || !Services.ads.ready || Services.state.adsFree) return;
    _loading = true;
    final width = MediaQuery.sizeOf(context).width.truncate();
    final AdSize size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width) ?? AdSize.banner;
    if (!mounted) {
      _loading = false;
      return;
    }
    final ad = BannerAd(
      adUnitId: AdIds.units.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad a) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (Ad a, LoadAdError error) {
          a.dispose();
          debugPrint('Banner failed: ${error.message}');
          if (!mounted) return;
          setState(() {
            _ad = null;
            _loaded = false;
          });
          _retry?.cancel();
          _retry = Timer(const Duration(seconds: 30), () => unawaited(_maybeLoad()));
        },
      ),
    );
    setState(() {
      _ad = ad;
      _size = size;
      _loading = false;
    });
    await ad.load();
  }

  void _release() {
    _retry?.cancel();
    _ad?.dispose();
    _ad = null;
    _loaded = false;
    _loading = false;
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
    if (Services.state.adsFree || ad == null || size == null) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: size.height.toDouble(),
      child: _loaded ? Center(child: SizedBox(width: size.width.toDouble(), height: size.height.toDouble(), child: AdWidget(ad: ad))) : null,
    );
  }
}
