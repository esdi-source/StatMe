import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/digestion_model.dart';
import '../repositories/repositories.dart';

/// Digestion Repository Provider
final digestionRepositoryProvider = Provider<DigestionRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoDigestionRepository();
  }
  return SupabaseDigestionRepository(Supabase.instance.client);
});

/// Digestion Entries Notifier - Toilettengänge
class DigestionEntriesNotifier extends StateNotifier<List<DigestionEntry>> {
  final DigestionRepository _repository;
  final String userId;
  
  DigestionEntriesNotifier(this._repository, this.userId) : super([]);
  
  Future<void> load() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    state = await _repository.getEntriesRange(userId, start, now);
  }
  
  /// Holt Einträge für einen bestimmten Tag
  List<DigestionEntry> getForDate(DateTime date) {
    return state.where((e) => 
      e.timestamp.year == date.year &&
      e.timestamp.month == date.month &&
      e.timestamp.day == date.day
    ).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  /// Holt Einträge für einen Zeitraum
  List<DigestionEntry> getForRange(DateTime start, DateTime end) {
    return state.where((e) {
      return e.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
             e.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
  
  /// Letzter Eintrag
  DigestionEntry? get lastEntry {
    if (state.isEmpty) return null;
    final sorted = [...state]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.first;
  }
  
  /// Einträge von heute
  List<DigestionEntry> get todayEntries {
    final now = DateTime.now();
    return getForDate(now);
  }
  
  /// Anzahl Stuhlgänge heute
  int get todayStoolCount {
    return todayEntries.where((e) => 
      e.type == ToiletType.stool || e.type == ToiletType.both
    ).length;
  }
  
  /// Durchschnittliche Konsistenz (letzte 7 Tage)
  double? get avgConsistencyLast7Days {
    final now = DateTime.now();
    final week = getForRange(now.subtract(const Duration(days: 7)), now);
    final stoolEntries = week.where((e) => e.consistency != null).toList();
    if (stoolEntries.isEmpty) return null;
    return stoolEntries.map((e) => e.consistency!.value).reduce((a, b) => a + b) 
           / stoolEntries.length;
  }
  
  /// Neuen Eintrag hinzufügen
  Future<DigestionEntry> add(DigestionEntry entry) async {
    final created = await _repository.addEntry(entry);
    state = [...state, created];
    return created;
  }
  
  /// Eintrag aktualisieren
  Future<void> update(DigestionEntry entry) async {
    final updated = await _repository.updateEntry(entry);
    state = state.map((e) => e.id == updated.id ? updated : e).toList();
  }
  
  /// Eintrag löschen
  Future<void> delete(String entryId) async {
    await _repository.deleteEntry(entryId);
    state = state.where((e) => e.id != entryId).toList();
  }
  
  /// Statistik: Einträge pro Tag (letzte n Tage)
  Map<DateTime, int> getEntriesPerDay(int days) {
    final now = DateTime.now();
    final result = <DateTime, int>{};
    
    for (var i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      result[date] = getForDate(date).length;
    }
    
    return result;
  }
}

final digestionEntriesProvider = StateNotifierProvider.family<DigestionEntriesNotifier, List<DigestionEntry>, String>((ref, userId) {
  final repository = ref.watch(digestionRepositoryProvider);
  return DigestionEntriesNotifier(repository, userId);
});

/// Provider für Tagesübersicht
final digestionDaySummaryProvider = Provider.family<DigestionDaySummary, ({String userId, DateTime date})>((ref, params) {
  // Note: This assumes the notifier has loaded data covering this date.
  // Ideally, we should fetch specifically for this date if not present, 
  // but for now we rely on the notifier's state.
  final entries = ref.watch(digestionEntriesProvider(params.userId));
  final dayEntries = entries.where((e) => 
    e.timestamp.year == params.date.year &&
    e.timestamp.month == params.date.month &&
    e.timestamp.day == params.date.day
  ).toList();
  
  return DigestionDaySummary(
    date: params.date,
    entries: dayEntries,
  );
});
