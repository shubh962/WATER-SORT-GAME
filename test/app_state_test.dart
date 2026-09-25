import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_sort/models/products.dart';
import 'package:water_sort/models/themes.dart';
import 'package:water_sort/services/app_state.dart';
import 'package:water_sort/services/storage.dart';

Future<AppState> makeState({DateTime Function()? clock}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final storage = await Storage.open();
  return AppState(storage, storage.load(), clock: clock);
}

void main() {
  test('coins: add and spend', () async {
    final s = await makeState();
    s.addCoins(100);
    expect(s.coins, 100);
    expect(s.spendCoins(30), isTrue);
    expect(s.coins, 70);
    expect(s.spendCoins(500), isFalse);
    expect(s.coins, 70);
    s.addCoins(-5);
    expect(s.coins, 70);
  });

  test('level only moves forward', () async {
    final s = await makeState();
    s.setLevel(7);
    s.setLevel(3);
    expect(s.level, 7);
  });

  test('buying a theme spends coins and equips it', () async {
    final s = await makeState();
    s.addCoins(500);
    expect(s.buyTheme('skin_emerald'), BuyThemeResult.ok);
    expect(s.coins, 100);
    expect(s.skinId, 'skin_emerald');
    expect(s.buyTheme('skin_emerald'), BuyThemeResult.alreadyOwned);
    expect(s.buyTheme('bg_ocean'), BuyThemeResult.notEnoughCoins);
  });

  test('PRO-only themes need PRO', () async {
    final s = await makeState();
    expect(s.buyTheme('skin_obsidian'), BuyThemeResult.proRequired);
    expect(s.equip('skin_obsidian'), isFalse);
    s.grantProduct(Products.byId(Products.proPass)!);
    expect(s.pro, isTrue);
    expect(s.adsFree, isTrue);
    expect(s.equip('skin_obsidian'), isTrue);
  });

  test('purchase tokens are processed only once', () async {
    final s = await makeState();
    expect(s.markProcessed('token-1'), isTrue);
    expect(s.markProcessed('token-1'), isFalse);
    expect(s.markProcessed('token-2'), isTrue);
  });

  test('coin pack grants coins, Remove Ads grants no coins', () async {
    final s = await makeState();
    s.grantProduct(Products.byId(Products.coins1500)!);
    expect(s.coins, 1500);
    s.grantProduct(Products.byId(Products.removeAds)!);
    expect(s.noAds, isTrue);
    expect(s.pro, isFalse);
    expect(s.coins, 1500);
  });

  test('daily reward: once a day, streak continues, resets after a gap', () async {
    var now = DateTime(2026, 9, 21, 9);
    final s = await makeState(clock: () => now);
    expect(s.daily.canClaim, isTrue);
    expect(s.claimDaily(), 50);
    expect(s.claimDaily(), 0); // same day
    now = DateTime(2026, 9, 22, 8);
    expect(s.claimDaily(), 75); // day 2
    now = DateTime(2026, 9, 25, 8);
    expect(s.claimDaily(), 50); // gap: back to day 1
    expect(s.streak, 1);
  });

  test('daily reward is doubled for PRO and for the video bonus', () async {
    final s = await makeState(clock: () => DateTime(2026, 9, 21));
    s.grantProduct(Products.byId(Products.proPass)!);
    expect(s.claimDaily(doubled: true), 200); // 50 * 2 (PRO) * 2 (video)
  });

  test('progress survives a restart', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = await Storage.open();
    final s = AppState(storage, storage.load());
    s.addCoins(500);
    s.setLevel(12);
    expect(s.buyTheme('skin_emerald'), BuyThemeResult.ok);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final reopened = (await Storage.open()).load();
    expect(reopened.coins, 100);
    expect(reopened.level, 12);
    expect(reopened.owned.contains('skin_emerald'), isTrue);
    expect(reopened.skin, 'skin_emerald');
  });

  test('theme JSON for the game has the fields the game expects', () {
    final skin = ThemeCatalog.skin('skin_gold').toJs();
    for (final k in <String>['glass', 'glow', 'tint', 'rim', 'cork', 'corkDark']) {
      expect(skin.containsKey(k), isTrue, reason: k);
    }
    final bg = ThemeCatalog.background('bg_ocean').toJs();
    for (final k in <String>['c1', 'c2', 'c3', 'bub']) {
      expect(bg.containsKey(k), isTrue, reason: k);
    }
    expect(skin['glass'], matches(RegExp(r'^#[0-9a-f]{6}$')));
  });
}
