import 'package:water_sort/config/app_config.dart';

/// Decides when a forced (interstitial) ad may appear. Pure Dart so it is unit tested.
/// Rules: never for Remove Ads / PRO, not before [firstLevel], only every
/// [everyN]th level break, and never within [cooldown] of the previous one.
class InterstitialPolicy {
  InterstitialPolicy({
    this.firstLevel = AdRules.firstInterstitialLevel,
    this.everyN = AdRules.everyNLevels,
    this.cooldown = AdRules.cooldown,
  });

  final int firstLevel;
  final int everyN;
  final Duration cooldown;
  int _breaks = 0;
  DateTime? _last;

  /// Call once per natural break (a finished level).
  bool isDue({required int level, required DateTime now, required bool adsFree}) {
    if (adsFree) return false;
    _breaks++;
    if (level < firstLevel) return false;
    if (_breaks < everyN) return false;
    final last = _last;
    if (last != null && now.difference(last) < cooldown) return false;
    return true;
  }

  void markShown(DateTime now) {
    _last = now;
    _breaks = 0;
  }
}
