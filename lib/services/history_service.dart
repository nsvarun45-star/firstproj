// lib/services/history_service.dart
//
// Persists completed wear/cleaning cycles locally using shared_preferences,
// storing the list of HistoryEntry objects as a JSON-encoded string.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';

class HistoryService {
  static const _storageKey = 'lensguard_history_entries';

  Future<List<HistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // newest first
  }

  Future<void> addEntry(HistoryEntry entry) async {
    final entries = await loadHistory();
    entries.insert(0, entry);
    await _saveAll(entries);
  }

  Future<void> deleteEntry(String id) async {
    final entries = await loadHistory();
    entries.removeWhere((e) => e.id == id);
    await _saveAll(entries);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _saveAll(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
