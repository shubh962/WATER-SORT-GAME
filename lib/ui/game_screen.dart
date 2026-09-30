import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:water_sort/services/game_bridge.dart';
import 'package:water_sort/services/services.dart';
import 'package:water_sort/services/telemetry.dart';
import 'package:water_sort/ui/routes.dart';
import 'package:water_sort/ui/theme.dart';
import 'package:water_sort/ui/widgets/banner_ad_view.dart';
import 'package:water_sort/ui/widgets/game_button.dart';

/// Hosts the HTML5 game in a WebView with the banner ad underneath it.
/// The game is bundled in assets/web/index.html and never loads remote content.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final WebViewController _controller;
  late final GameBridge _bridge;
  String? _html;
  bool _ready = false;
  bool _failed = false;
  bool _overlayRoute = false; // Shop / PRO open above the game
  Timer? _readyTimeout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController();
    _bridge = GameBridge(
      controller: _controller,
      state: Services.state,
      ads: Services.ads,
      review: Services.review,
      onNavigate: _onNavigate,
      onReady: () {
        _readyTimeout?.cancel();
        if (mounted) setState(() => _ready = true);
      },
    );
    Services.ads.adShowing.addListener(_onAdShowing);

    // webview_flutter is Android/iOS functionality. On Flutter Web,
    // do not call WebViewController platform methods because they are
    // not implemented by the web platform.
    if (!kIsWeb) {
      _configureWebView();
      _bridge.attach();
      unawaited(_load());
    }
  }

  void _configureWebView() {
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bgMid)
      ..enableZoom(false)
      ..addJavaScriptChannel('FlutterHost', onMessageReceived: (JavaScriptMessage m) => unawaited(_bridge.onMessage(m.message)))
      ..setNavigationDelegate(NavigationDelegate(
        // The game is a single local page. Block everything else.
        onNavigationRequest: (NavigationRequest r) =>
            (r.url == 'about:blank' || r.url.startsWith('data:')) ? NavigationDecision.navigate : NavigationDecision.prevent,
        onWebResourceError: (WebResourceError e) {
          if (e.isForMainFrame ?? false) {
            Telemetry.error(e.description, null, reason: 'webview');
            if (mounted) setState(() => _failed = true);
          }
        },
      ));
    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      unawaited(AndroidWebViewController.enableDebugging(kDebugMode));
      unawaited(platform.setMediaPlaybackRequiresUserGesture(false));
    }
  }

  Future<void> _load() async {
    try {
      _html ??= await rootBundle.loadString('assets/web/index.html');
      if (!mounted) return;
      setState(() {
        _failed = false;
        _ready = false;
      });
      await _controller.loadHtmlString(_html!);
      _readyTimeout?.cancel();
      _readyTimeout = Timer(const Duration(seconds: 12), () {
        if (mounted && !_ready) setState(() => _failed = true);
      });
    } catch (e, s) {
      Telemetry.error(e, s, reason: 'game.load');
      if (mounted) setState(() => _failed = true);
    }
  }

  // ---- navigation requested by the game ----
  Future<void> _onNavigate(String to) async {
    if (!mounted) return;
    switch (to) {
      case 'home':
        Navigator.of(context).pop();
      case 'shop':
        await _openOverlay(() => pushShop(context));
      case 'pro':
        await _openOverlay(() => pushPro(context));
    }
  }

  Future<void> _openOverlay(Future<void> Function() open) async {
    _overlayRoute = true;
    unawaited(_bridge.sendEvent('pause'));
    await open();
    _overlayRoute = false;
    if (!mounted) return;
    _bridge.pushState(); // coins / PRO / theme may have changed
    unawaited(_bridge.sendEvent('resume'));
  }

  void _onAdShowing() {
    unawaited(_bridge.sendEvent(Services.ads.adShowing.value ? 'pause' : 'resume'));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_overlayRoute && !Services.ads.adShowing.value) unawaited(_bridge.sendEvent('resume'));
    } else {
      unawaited(_bridge.sendEvent('pause'));
    }
  }

  @override
  void dispose() {
    _readyTimeout?.cancel();
    Services.ads.adShowing.removeListener(_onAdShowing);
    _bridge.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The actual game is intentionally Android-only. Flutter Web is used
    // only for development/preview, so show a friendly screen instead of
    // invoking unsupported WebView APIs in Chrome.
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: AppColors.bgMid,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.phone_android_rounded,
                    size: 72,
                    color: AppColors.teal,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Android Version Required',
                    style: kTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Water Sort is designed to run as an Android game. '
                    'Build and run the Android version to play the game.',
                    style: kDim,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  GameButton(
                    label: 'Back to Home',
                    style: GameButtonStyle.purple,
                    onPressed: () => Navigator.of(context).pop(),
                    expand: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false, // the Android back button goes to the game first (close popup / pause menu)
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (_failed) {
          Navigator.of(context).pop();
        } else {
          unawaited(_bridge.sendEvent('back'));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgMid,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: <Widget>[
                    WebViewWidget(controller: _controller),
                    if (!_ready && !_failed) const _Loading(),
                    if (_failed)
                      _LoadError(
                        onRetry: _load,
                        onHome: () => Navigator.of(context).pop(),
                      ),
                  ],
                ),
              ),
              const BannerAdView(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.bgMid,
      child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry, required this.onHome});
  final VoidCallback onRetry;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bgMid,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.red),
              const SizedBox(height: 12),
              const Text('The game could not start', style: kTitle, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              const Text('Update "Android System WebView" in the Play Store, then try again.', style: kDim, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              GameButton(label: 'Try again', onPressed: onRetry, expand: false),
              const SizedBox(height: 4),
              GameButton(label: 'Home', style: GameButtonStyle.purple, onPressed: onHome, expand: false),
            ],
          ),
        ),
      ),
    );
  }
}
