import 'package:flutter/foundation.dart';
import 'package:water_sort/config/app_config.dart';
import 'package:water_sort/config/economy.dart';
import 'package:water_sort/models/products.dart';
import 'package:water_sort/models/save_data.dart';
import 'package:water_sort/models/themes.dart';
import 'package:water_sort/services/storage.dart';
import 'package:water_sort/services/telemetry.dart';

enum BuyThemeResult { ok, notEnoughCoins, proRequired, alreadyOwned, unknown }

class DailyStatus {
  const DailyStatus({required this.canClaim, required this.streak, required this.reward});
  final bool canClaim;
  final int streak; // streak that will be reached (or the current one if claimed)
  final int reward; // base coins before PRO / video multipliers
}

/// Pure date logic, kept separate so it is easy to unit test.
class DailyReward {
  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int rewardFor(int streak) {
    final list = Economy.dailyRewards;
    final i = streak <= 0 ? 0 : (streak - 1) % list.length;
    return list[i];
  }

  static DailyStatus status({required String lastDaily, required int streak, required DateTime now}) {
    final today = dateKey(now);
    if (lastDaily == today) {
      return DailyStatus(canClaim: false, streak: streak, reward: rewardFor(streak));
    }
    final yesterday = dateKey(DateTime(now.year, now.month, now.day - 1));
    final next = (lastDaily == yesterday) ? streak + 1 : 1;
    return DailyStatus(canClaim: true, streak: next, reward: rewardFor(next));
  }
}

/// Single source of truth for coins, progress, purchases and settings.
/// The HTML game asks this class (through the bridge) to add or spend coins.
class AppState extends ChangeNotifier {
  AppState(this._storage, this._data, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final Storage _storage;
  final SaveData _data;
  final DateTime Function() _clock;
  Future<void> _writes = Future<void>.value();

  // ---- reads ----
  int get coins => _data.coins;
  int get level => _data.level;
  bool get muted => _data.muted;
  bool get haptics => _data.haptics;
  bool get noAds => _data.noAds;
  bool get pro => _data.pro;
  bool get adsFree => _data.noAds || _data.pro;
  String get skinId => _data.skin;
  String get bgId => _data.bg;
  int get streak => _data.streak;
  Map<String, dynamic> get kv => Map<String, dynamic>.from(_data.kv);
  int get sessions => _data.sessions;

  bool owns(String themeId) {
    final t = ThemeCatalog.byId(themeId);
    if (t == null) return false;
    if (t.proOnly) return _data.pro;
    return t.price == 0 || _data.owned.contains(themeId);
  }

  DailyStatus get daily =>
      DailyReward.status(lastDaily: _data.lastDaily, streak: _data.streak, now: _clock());

  // ---- writes ----
  void _commit() {
    notifyListeners();
    _writes = _writes
        .then((_) => _storage.save(_data))
        .catchError((Object e, StackTrace s) => Telemetry.error(e, s, reason: 'save'));
  }

  void noteSession() {
    _data.sessions++;
    _commit();
  }

  void addCoins(int amount, {String reason = ''}) {
    if (amount <= 0) return;
    _data.coins += amount;
    Telemetry.event('coins_earn', <String, Object?>{'amount': amount, 'reason': reason});
    _commit();
  }

  bool spendCoins(int amount, {String reason = ''}) {
    if (amount <= 0 || _data.coins < amount) return false;
    _data.coins -= amount;
    Telemetry.event('coins_spend', <String, Object?>{'amount': amount, 'reason': reason});
    _commit();
    return true;
  }

  /// Progress only moves forward.
  void setLevel(int newLevel) {
    if (newLevel <= _data.level) return;
    _data.level = newLevel;
    _commit();
  }

  void setMuted(bool value) {
    if (_data.muted == value) return;
    _data.muted = value;
    _commit();
  }

  void setHaptics(bool value) {
    if (_data.haptics == value) return;
    _data.haptics = value;
    _commit();
  }

  void setKv(String key, Object? value) {
    _data.kv[key] = value;
    _commit();
  }

  BuyThemeResult buyTheme(String id) {
    final t = ThemeCatalog.byId(id);
    if (t == null) return BuyThemeResult.unknown;
    if (owns(id)) return BuyThemeResult.alreadyOwned;
    if (t.proOnly) return BuyThemeResult.proRequired;
    if (!spendCoins(t.price, reason: 'theme:$id')) return BuyThemeResult.notEnoughCoins;
    _data.owned.add(id);
    equip(id);
    return BuyThemeResult.ok;
  }

  bool equip(String id) {
    final t = ThemeCatalog.byId(id);
    if (t == null || !owns(id)) return false;
    if (t.kind == ThemeKind.skin) {
      _data.skin = id;
    } else {
      _data.bg = id;
    }
    _commit();
    return true;
  }

  /// Returns the coins granted, or 0 if today's reward was already claimed.
  int claimDaily({bool doubled = false}) {
    final s = daily;
    if (!s.canClaim) return 0;
    var amount = s.reward;
    if (pro) amount *= 2;
    if (doubled) amount *= 2;
    _data.streak = s.streak;
    _data.lastDaily = DailyReward.dateKey(_clock());
    _data.coins += amount;
    Telemetry.event('daily_claim', <String, Object?>{'streak': s.streak, 'amount': amount});
    _commit();
    return amount;
  }

  /// True the first time a purchase token is seen. Prevents double grants when
  /// the store re-delivers a purchase (app crash, restore, reinstall with backup).
  bool markProcessed(String key) {
    if (_data.processed.contains(key)) return false;
    _data.processed.add(key);
    if (_data.processed.length > 200) {
      _data.processed.removeRange(0, _data.processed.length - 200);
    }
    _commit();
    return true;
  }

  void grantProduct(StoreProduct p) {
    if (p.coins > 0) _data.coins += p.coins;
    if (p.removesAds) _data.noAds = true;
    if (p.grantsPro) _data.pro = true;
    Telemetry.event('purchase_granted', <String, Object?>{'id': p.id});
    _commit();
  }

  // ---- what the HTML game receives ----
  Map<String, Object?> gameState({bool includeLevel = false}) => <String, Object?>{
        'coins': coins,
        if (includeLevel) 'level': level,
        'noAds': noAds,
        'pro': pro,
        'muted': muted,
        'haptics': haptics,
        'skin': ThemeCatalog.skin(skinId).toJs(),
        'bg': ThemeCatalog.background(bgId).toJs(),
        'kv': kv,
        'prices': Economy.prices,
        'debug': AppConfig.debugTools,
      };
}
