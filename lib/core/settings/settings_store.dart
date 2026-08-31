import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  static const _prefsKey = 'provider_secrets';

  Map<String, String> values = {};

  Map<String, String> snapshot() => Map<String, String>.from(values);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      values = {};
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        values = {};
        return;
      }
      values = {
        for (final entry in decoded.entries)
          if (entry.value is String && (entry.value as String).trim().isNotEmpty)
            entry.key.toString(): (entry.value as String).trim(),
      };
    } catch (_) {
      values = {};
    }
  }

  Future<void> set(String key, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      values.remove(key);
    } else {
      values[key] = trimmed;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(values));
  }
}
