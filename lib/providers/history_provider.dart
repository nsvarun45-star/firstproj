// lib/providers/history_provider.dart
//
// Exposes the list of HistoryEntry records as an AsyncNotifier, backed by
// HistoryService for persistence. Used by the History screen and by
// wear_timer_provider/cleaning_provider when saving completed sessions.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/history_entry.dart';
import 'service_providers.dart';

class HistoryNotifier extends AsyncNotifier<List<HistoryEntry>> {
  @override
  Future<List<HistoryEntry>> build() async {
    final service = ref.read(historyServiceProvider);
    return service.loadHistory();
  }

  Future<void> addEntry(HistoryEntry entry) async {
    final service = ref.read(historyServiceProvider);
    await service.addEntry(entry);
    state = AsyncData(await service.loadHistory());
  }

  Future<void> deleteEntry(String id) async {
    final service = ref.read(historyServiceProvider);
    await service.deleteEntry(id);
    state = AsyncData(await service.loadHistory());
  }

  Future<void> clearAll() async {
    final service = ref.read(historyServiceProvider);
    await service.clearAll();
    state = const AsyncData([]);
  }
}

final historyProvider = AsyncNotifierProvider<HistoryNotifier, List<HistoryEntry>>(
  HistoryNotifier.new,
);
