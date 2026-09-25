import 'package:in_app_review/in_app_review.dart';
import 'package:water_sort/services/app_state.dart';
import 'package:water_sort/services/telemetry.dart';

/// Asks for a Play Store rating at happy moments only (after a won level),
/// at most once every 60 days. Google also rate-limits the dialog itself.
class ReviewService {
  ReviewService(this._state);
  final AppState _state;
  static const int _minDays = 60;

  Future<void> maybeAsk() async {
    try {
      final last = (_state.kv['lastReview'] as num?)?.toInt() ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (last != 0 && now - last < _minDays * Duration.millisecondsPerDay) return;
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      _state.setKv('lastReview', now);
      await review.requestReview();
      Telemetry.event('review_prompt');
    } catch (e, s) {
      Telemetry.error(e, s, reason: 'review');
    }
  }

  /// Settings > "Rate the game" (opens the Play Store page).
  Future<void> openStore() async {
    try {
      await InAppReview.instance.openStoreListing();
    } catch (e, s) {
      Telemetry.error(e, s, reason: 'review.open');
    }
  }
}
