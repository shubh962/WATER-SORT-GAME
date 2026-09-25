import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:water_sort/services/ads_service.dart';
import 'package:water_sort/services/app_state.dart';
import 'package:water_sort/services/review_service.dart';
import 'package:water_sort/services/telemetry.dart';

/// Talks to the HTML game through the JavaScript channel "FlutterHost".
///
/// Game -> Flutter: JSON  {id, type, payload}. If id != 0 a reply is expected:
///   window.__hostReply(id, result)
/// Flutter -> Game: window.__hostEvent(name, data)  (state, pause, resume, back)
///
/// Flutter owns coins, level, purchases and settings. The game can only ask.
class GameBridge {
  GameBridge({
    required this.controller,
    required this.state,
    required this.ads,
    required this.review,
    required this.onNavigate,
    required this.onReady,
  });

  final WebViewController controller;
  final AppState state;
  final AdsService ads;
  final ReviewService review;
  final void Function(String destination) onNavigate;
  final void Function() onReady;

  String _lastSnapshot = '';

  void attach() {
    _lastSnapshot = _snapshot();
    state.addListener(_onStateChanged);
  }

  void dispose() => state.removeListener(_onStateChanged);

  // Purchases or theme changes made while the game is open are pushed live.
  // Coin changes are NOT pushed here, because the game animates its own coins.
  String _snapshot() => jsonEncode(<Object?>[state.pro, state.noAds, state.skinId, state.bgId, state.muted, state.haptics]);

  void _onStateChanged() {
    final s = _snapshot();
    if (s == _lastSnapshot) return;
    _lastSnapshot = s;
    pushState();
  }

  /// Sends the full state (including coins). Call after returning from Shop/PRO.
  void pushState() => sendEvent('state', state.gameState());

  Future<void> sendEvent(String name, [Object? data]) {
    return _run('window.__hostEvent(${jsonEncode(name)}, ${jsonEncode(data ?? <String, Object?>{})})');
  }

  Future<void> _reply(int id, Object? result) => _run('window.__hostReply($id, ${jsonEncode(result)})');

  Future<void> _run(String js) async {
    try {
      await controller.runJavaScript(js);
    } catch (e, s) {
      Telemetry.error(e, s, reason: 'bridge.js');
    }
  }

  Future<void> onMessage(String raw) async {
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return; // ignore malformed messages
    }
    final id = (msg['id'] as num?)?.toInt() ?? 0;
    final type = msg['type'] as String? ?? '';
    final payload = (msg['payload'] is Map) ? Map<String, dynamic>.from(msg['payload'] as Map) : <String, dynamic>{};
    try {
      final result = await handle(type, payload);
      if (id != 0) await _reply(id, result);
    } catch (e, s) {
      Telemetry.error(e, s, reason: 'bridge:$type');
      if (id != 0) await _reply(id, <String, Object?>{'error': 'internal'});
    }
  }

  /// Public so it can be unit tested without a WebView.
  Future<Map<String, Object?>> handle(String type, Map<String, dynamic> p) async {
    switch (type) {
      case 'boot':
        return state.gameState(includeLevel: true);

      case 'ready':
        onReady();
        return <String, Object?>{};

      case 'coins.add': {
        final amount = _int(p['amount']).clamp(0, 5000).toInt(); // sanity limit per call
        state.addCoins(amount, reason: '${p['reason'] ?? 'game'}');
        return <String, Object?>{'coins': state.coins};
      }

      case 'coins.spend': {
        final amount = _int(p['amount']).clamp(0, 100000).toInt();
        final ok = state.spendCoins(amount, reason: '${p['reason'] ?? 'game'}');
        return <String, Object?>{'ok': ok, 'coins': state.coins};
      }

      case 'progress.level':
        state.setLevel(_int(p['level']));
        return <String, Object?>{};

      case 'settings.muted':
        state.setMuted(p['muted'] == true);
        return <String, Object?>{};

      case 'kv.set': {
        final key = p['key'];
        if (key is String && key.length <= 40) state.setKv(key, p['value']);
        return <String, Object?>{};
      }

      case 'ads.interstitial': {
        final shown = await ads.maybeShowInterstitial(level: _int(p['level']));
        return <String, Object?>{'shown': shown};
      }

      case 'ads.rewarded': {
        final r = await ads.showRewarded(placement: '${p['placement'] ?? 'unknown'}');
        return <String, Object?>{'rewarded': r.rewarded, if (r.reason != null) 'reason': r.reason};
      }

      case 'nav':
        onNavigate('${p['to']}');
        return <String, Object?>{};

      case 'haptic':
        if (state.haptics) {
          switch (p['kind']) {
            case 'heavy':
              unawaited(HapticFeedback.heavyImpact());
            case 'medium':
              unawaited(HapticFeedback.mediumImpact());
            default:
              unawaited(HapticFeedback.lightImpact());
          }
        }
        return <String, Object?>{};

      case 'analytics': {
        final name = '${p['name']}';
        final params = (p['params'] is Map) ? Map<String, Object?>.from(p['params'] as Map) : <String, Object?>{};
        Telemetry.event(name, params);
        return <String, Object?>{};
      }

      case 'review.maybe':
        unawaited(review.maybeAsk());
        return <String, Object?>{};

      case 'log':
        Telemetry.error('JS: ${p['msg']} (line ${p['line']})', null, reason: 'webview');
        return <String, Object?>{};

      default:
        return <String, Object?>{'error': 'unknown_type'};
    }
  }

  static int _int(Object? v) => (v is num) ? v.toInt() : 0;
}
