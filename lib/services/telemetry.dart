import 'package:flutter/foundation.dart';

/// Analytics + crash reporting hook. Ships with a debug-console sink so the app
/// has no Firebase dependency out of the box. To add Firebase later, implement
/// [TelemetrySink] (Analytics + Crashlytics) and set `Telemetry.sink` in main().
abstract class TelemetrySink {
  void event(String name, Map<String, Object?> params);
  void error(Object error, StackTrace? stack, {String? reason});
}

class DebugSink implements TelemetrySink {
  const DebugSink();

  @override
  void event(String name, Map<String, Object?> params) {
    if (kDebugMode) debugPrint('[event] $name $params');
  }

  @override
  void error(Object error, StackTrace? stack, {String? reason}) {
    debugPrint('[error] ${reason ?? ''} $error');
    if (kDebugMode && stack != null) debugPrint('$stack');
  }
}

class Telemetry {
  static TelemetrySink sink = const DebugSink();

  static void event(String name, [Map<String, Object?> params = const <String, Object?>{}]) {
    try {
      sink.event(name, params);
    } catch (_) {/* telemetry must never crash the app */}
  }

  static void error(Object error, StackTrace? stack, {String? reason}) {
    try {
      sink.error(error, stack, reason: reason);
    } catch (_) {}
  }
}
