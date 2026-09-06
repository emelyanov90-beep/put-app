import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A list of JSON objects kept on the device under one key.
///
/// Used by the sections that have no server counterpart yet (saved routes,
/// mock payment methods). Nothing here is shared between devices, and nothing
/// sensitive may be written: see the note on the payment repository.
class LocalJsonStore {
  const LocalJsonStore(this.key);

  final String key;

  Future<List<Map<String, dynamic>>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> write(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
