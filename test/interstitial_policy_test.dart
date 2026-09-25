import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort/services/interstitial_policy.dart';

void main() {
  final t0 = DateTime(2026, 9, 21, 12);

  test('never shows for Remove Ads / PRO', () {
    final p = InterstitialPolicy(firstLevel: 1, everyN: 1, cooldown: Duration.zero);
    expect(p.isDue(level: 50, now: t0, adsFree: true), isFalse);
  });

  test('never before the first allowed level', () {
    final p = InterstitialPolicy(firstLevel: 4, everyN: 1, cooldown: Duration.zero);
    expect(p.isDue(level: 2, now: t0, adsFree: false), isFalse);
    expect(p.isDue(level: 3, now: t0, adsFree: false), isFalse);
    expect(p.isDue(level: 4, now: t0, adsFree: false), isTrue);
  });

  test('only every Nth level break', () {
    final p = InterstitialPolicy(firstLevel: 1, everyN: 3, cooldown: Duration.zero);
    expect(p.isDue(level: 5, now: t0, adsFree: false), isFalse);
    expect(p.isDue(level: 6, now: t0, adsFree: false), isFalse);
    expect(p.isDue(level: 7, now: t0, adsFree: false), isTrue);
    p.markShown(t0);
    expect(p.isDue(level: 8, now: t0, adsFree: false), isFalse);
  });

  test('respects the cooldown', () {
    final p = InterstitialPolicy(firstLevel: 1, everyN: 1, cooldown: const Duration(seconds: 60));
    expect(p.isDue(level: 5, now: t0, adsFree: false), isTrue);
    p.markShown(t0);
    expect(p.isDue(level: 6, now: t0.add(const Duration(seconds: 30)), adsFree: false), isFalse);
    expect(p.isDue(level: 7, now: t0.add(const Duration(seconds: 61)), adsFree: false), isTrue);
  });
}
