import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Analytics + crash reporting hook.
///
/// Ships with [BufferedSink], which keeps the last [BufferedSink.maxEntries]
/// events and errors in memory (release builds included, not just debug), so
/// there is something to inspect during closed testing even before a real
/// backend is wired in — e.g. surface [BufferedSink.dump] on a hidden debug
/// screen, or ask testers to paste it into a bug report.
///
/// TO ADD REAL CRASH/ANALYTICS REPORTING (recommended before wider rollout):
/// 1. Add `firebase_core`, `firebase_analytics`, `firebase_crashlytics` to
///    pubspec.yaml and run `flutterfire configure` with your Firebase
///    project (this generates the `google-services.json` / platform config
///    that isn't part of this source tree).
/// 2. Implement [TelemetrySink] with calls to
///    `FirebaseAnalytics.instance.logEvent(...)` and
///    `FirebaseCrashlytics.instance.recordError(...)`.
/// 3. In `main()`, before `runApp`, set:
///    `Telemetry.sink = CompositeSink([FirebaseTelemetrySink(), const BufferedSink()]);`
///    (kept below as [CompositeSink] so you don't lose the in-memory buffer
///    when Firebase is added.)
abstract class TelemetrySink {
  void event(String name, Map<String, Object?> params);
  void error(Object error, StackTrace? stack, {String? reason});
}

/// Prints to the debug console. Silent in release builds — kept only for
/// local development; [BufferedSink] is the default in [Telemetry.sink].
class DebugSink implements TelemetrySink {
  const DebugSink();

  @override
  void event(String name, Map<String, Object?> params) {
    if (kDebugMode) debugPrint('[event] $name $params');
  }

  @override
  void error(Object error, StackTrace? stack, {String? reason}) {
    if (!kDebugMode) return;
    debugPrint('[error] ${reason ?? ''} $error');
    if (stack != null) debugPrint('$stack');
  }
}

/// One recorded telemetry entry, kept for later inspection.
class TelemetryEntry {
  TelemetryEntry.event(this.name, this.params)
      : isError = false,
        error = null,
        stack = null,
        reason = null,
        time = DateTime.now();

  TelemetryEntry.error(this.error, this.stack, this.reason)
      : isError = true,
        name = 'error',
        params = const <String, Object?>{},
        time = DateTime.now();

  final DateTime time;
  final bool isError;
  final String name;
  final Map<String, Object?> params;
  final Object? error;
  final StackTrace? stack;
  final String? reason;

  @override
  String toString() {
    final ts = time.toIso8601String();
    if (isError) return '[$ts] ERROR ${reason ?? ''}: $error';
    return '[$ts] $name $params';
  }
}

/// Keeps the most recent entries in memory so closed-testing issues can be
/// inspected without a backend. Always active, release builds included.
/// Also prints in debug mode so `flutter run` output stays useful.
class BufferedSink implements TelemetrySink {
  BufferedSink({this.maxEntries = 200});

  final int maxEntries;
  final Queue<TelemetryEntry> _entries = Queue<TelemetryEntry>();
  static const DebugSink _debugPrinter = DebugSink();

  UnmodifiableListView<TelemetryEntry> get entries => UnmodifiableListView<TelemetryEntry>(_entries);

  void _add(TelemetryEntry e) {
    _entries.addLast(e);
    while (_entries.length > maxEntries) {
      _entries.removeFirst();
    }
  }

  @override
  void event(String name, Map<String, Object?> params) {
    _add(TelemetryEntry.event(name, params));
    _debugPrinter.event(name, params);
  }

  @override
  void error(Object error, StackTrace? stack, {String? reason}) {
    _add(TelemetryEntry.error(error, stack, reason));
    _debugPrinter.error(error, stack, reason: reason);
  }

  /// Plain-text dump of everything currently buffered, newest last.
  /// Useful for a "copy debug log" button or attaching to a bug report.
  String dump() => _entries.map((TelemetryEntry e) => e.toString()).join('\n');

  void clear() => _entries.clear();
}

/// Fans out to multiple sinks, e.g. a real backend plus [BufferedSink] so the
/// in-memory log stays available even after a real backend is wired in.
class CompositeSink implements TelemetrySink {
  const CompositeSink(this.sinks);
  final List<TelemetrySink> sinks;

  @override
  void event(String name, Map<String, Object?> params) {
    for (final s in sinks) {
      s.event(name, params);
    }
  }

  @override
  void error(Object error, StackTrace? stack, {String? reason}) {
    for (final s in sinks) {
      s.error(error, stack, reason: reason);
    }
  }
}

class Telemetry {
  static TelemetrySink sink = BufferedSink();

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
