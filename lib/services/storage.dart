import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_sort/models/save_data.dart';
import 'package:water_sort/services/telemetry.dart';

/// Persists [SaveData] as one JSON blob, with a backup copy of the previous
/// save. If the main copy is corrupt the backup is used, then defaults.
class Storage {
  Storage._(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'save_v1';
  static const String _backupKey = 'save_v1_bak';

  static Future<Storage> open() async => Storage._(await SharedPreferences.getInstance());

  SaveData load() {
    for (final k in <String>[_key, _backupKey]) {
      final raw = _prefs.getString(k);
      if (raw == null) continue;
      try {
        return SaveData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e, s) {
        Telemetry.error(e, s, reason: 'save corrupt ($k)');
      }
    }
    return SaveData();
  }

  Future<void> save(SaveData data) async {
    final previous = _prefs.getString(_key);
    if (previous != null) await _prefs.setString(_backupKey, previous);
    await _prefs.setString(_key, data.encode());
  }
}
