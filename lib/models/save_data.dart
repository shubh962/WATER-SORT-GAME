import 'dart:convert';

import 'package:water_sort/models/themes.dart';

/// Everything that is persisted. Bump [currentVersion] and extend [fromJson]
/// when the shape changes, so old saves keep working.
class SaveData {
  SaveData({
    this.coins = 0,
    this.level = 1,
    this.muted = false,
    this.haptics = true,
    this.noAds = false,
    this.pro = false,
    Set<String>? owned,
    this.skin = ThemeCatalog.defaultSkin,
    this.bg = ThemeCatalog.defaultBg,
    this.streak = 0,
    this.lastDaily = '',
    List<String>? processed,
    Map<String, dynamic>? kv,
    this.sessions = 0,
  })  : owned = owned ?? <String>{ThemeCatalog.defaultSkin, ThemeCatalog.defaultBg},
        processed = processed ?? <String>[],
        kv = kv ?? <String, dynamic>{};

  static const int currentVersion = 1;

  int coins;
  int level; // highest level reached (the level the player continues from)
  bool muted;
  bool haptics;
  bool noAds;
  bool pro;
  Set<String> owned; // owned theme ids
  String skin;
  String bg;
  int streak; // daily reward streak
  String lastDaily; // yyyy-mm-dd of the last claim
  List<String> processed; // handled purchase tokens (prevents double grants)
  Map<String, dynamic> kv; // small free-form store used by the game
  int sessions;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': currentVersion,
        'coins': coins,
        'level': level,
        'muted': muted,
        'haptics': haptics,
        'noAds': noAds,
        'pro': pro,
        'owned': owned.toList(),
        'skin': skin,
        'bg': bg,
        'streak': streak,
        'lastDaily': lastDaily,
        'processed': processed,
        'kv': kv,
        'sessions': sessions,
      };

  factory SaveData.fromJson(Map<String, dynamic> j) {
    int i(String k, int d) => (j[k] is num) ? (j[k] as num).toInt() : d;
    bool b(String k, bool d) => (j[k] is bool) ? j[k] as bool : d;
    String s(String k, String d) => (j[k] is String) ? j[k] as String : d;
    final owned = <String>{
      ThemeCatalog.defaultSkin,
      ThemeCatalog.defaultBg,
      if (j['owned'] is List) ...(j['owned'] as List).whereType<String>(),
    };
    return SaveData(
      coins: i('coins', 0).clamp(0, 100000000).toInt(),
      level: i('level', 1).clamp(1, 1000000).toInt(),
      muted: b('muted', false),
      haptics: b('haptics', true),
      noAds: b('noAds', false),
      pro: b('pro', false),
      owned: owned,
      skin: s('skin', ThemeCatalog.defaultSkin),
      bg: s('bg', ThemeCatalog.defaultBg),
      streak: i('streak', 0),
      lastDaily: s('lastDaily', ''),
      processed: (j['processed'] is List)
          ? (j['processed'] as List).whereType<String>().toList()
          : <String>[],
      kv: (j['kv'] is Map) ? Map<String, dynamic>.from(j['kv'] as Map) : <String, dynamic>{},
      sessions: i('sessions', 0),
    );
  }

  String encode() => jsonEncode(toJson());
}
