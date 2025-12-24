import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/supplement_model.dart';
import '../repositories/repositories.dart';

/// Supplements Repository Provider
final supplementsRepositoryProvider = Provider<SupplementsRepository>((ref) {
  if (AppConfig.isDemoMode) {
    return DemoSupplementsRepository();
  }
  return SupabaseSupplementsRepository(Supabase.instance.client);
});

/// Supplements Notifier - Nahrungsergänzungsmittel
class SupplementsNotifier extends StateNotifier<List<Supplement>> {
  final SupplementsRepository _repository;
  String? _userId;
  
  SupplementsNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    state = await _repository.getSupplements(userId);
  }
  
  /// Aktive (nicht pausierte) Supplements
  List<Supplement> get active => state.where((s) => !s.isPaused).toList();
  
  /// Supplement nach ID
  Supplement? getById(String id) {
    return state.cast<Supplement?>().firstWhere((s) => s?.id == id, orElse: () => null);
  }
  
  /// Supplements nach Kategorie
  List<Supplement> byCategory(SupplementCategory category) {
    return state.where((s) => s.category == category).toList();
  }
  
  /// Neues Supplement hinzufügen
  Future<Supplement> add(Supplement supplement) async {
    final created = await _repository.addSupplement(supplement);
    state = [...state, created];
    return created;
  }
  
  /// Supplement aktualisieren
  Future<void> update(Supplement supplement) async {
    final updated = await _repository.updateSupplement(supplement);
    state = state.map((s) => s.id == updated.id ? updated : s).toList();
  }
  
  /// Supplement löschen
  Future<void> delete(String supplementId) async {
    await _repository.deleteSupplement(supplementId);
    state = state.where((s) => s.id != supplementId).toList();
  }
}

final supplementsProvider = StateNotifierProvider.family<SupplementsNotifier, List<Supplement>, String>((ref, userId) {
  final repository = ref.watch(supplementsRepositoryProvider);
  final notifier = SupplementsNotifier(repository);
  notifier.load(userId);
  return notifier;
});

/// Supplement Intakes Notifier - Einnahmen
class SupplementIntakesNotifier extends StateNotifier<List<SupplementIntake>> {
  final SupplementsRepository _repository;
  String? _userId;
  
  SupplementIntakesNotifier(this._repository) : super([]);
  
  Future<void> load(String userId) async {
    _userId = userId;
    final now = DateTime.now();
    // Load last 30 days by default
    final start = now.subtract(const Duration(days: 30));
    state = await _repository.getIntakesRange(userId, start, now);
  }
  
  /// Einnahmen für einen bestimmten Tag
  List<SupplementIntake> getForDate(DateTime date) {
    return state.where((e) => 
      e.timestamp.year == date.year &&
      e.timestamp.month == date.month &&
      e.timestamp.day == date.day
    ).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  /// Einnahmen für einen Zeitraum
  List<SupplementIntake> getForRange(DateTime start, DateTime end) {
    return state.where((e) {
      return e.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
             e.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
  
  /// Einnahmen heute
  List<SupplementIntake> get todayIntakes {
    final now = DateTime.now();
    return getForDate(now);
  }
  
  /// Einnahmen eines bestimmten Supplements heute
  List<SupplementIntake> todayIntakesFor(String supplementId) {
    return todayIntakes.where((i) => i.supplementId == supplementId).toList();
  }
  
  /// Neue Einnahme hinzufügen
  Future<SupplementIntake> add(SupplementIntake intake) async {
    final created = await _repository.addIntake(intake);
    state = [...state, created];
    return created;
  }
  
  /// Einnahme aktualisieren
  Future<void> update(SupplementIntake intake) async {
    final updated = await _repository.updateIntake(intake);
    state = state.map((i) => i.id == updated.id ? updated : i).toList();
  }
  
  /// Einnahme löschen
  Future<void> delete(String intakeId) async {
    await _repository.deleteIntake(intakeId);
    state = state.where((i) => i.id != intakeId).toList();
  }
  
  /// Alle Einnahmen eines Supplements löschen
  Future<void> deleteForSupplement(String supplementId) async {
    // Note: Repository doesn't have deleteForSupplement, so we'd need to implement it or iterate.
    // For now, we'll just remove from state and assume the user deletes the supplement which might cascade delete intakes in DB.
    // Or we iterate and delete.
    final intakesToDelete = state.where((i) => i.supplementId == supplementId).toList();
    for (final intake in intakesToDelete) {
      await _repository.deleteIntake(intake.id);
    }
    state = state.where((i) => i.supplementId != supplementId).toList();
  }
}

final supplementIntakesProvider = StateNotifierProvider.family<SupplementIntakesNotifier, List<SupplementIntake>, String>((ref, userId) {
  final repository = ref.watch(supplementsRepositoryProvider);
  final notifier = SupplementIntakesNotifier(repository);
  notifier.load(userId);
  return notifier;
});

/// Provider für Supplement-Statistiken
final supplementStatisticsProvider = Provider.family<SupplementStatistics, ({String userId, int days})>((ref, params) {
  final supplements = ref.watch(supplementsProvider(params.userId));
  final intakes = ref.watch(supplementIntakesProvider(params.userId));
  
  return SupplementStatistics.calculate(
    supplements: supplements,
    intakes: intakes,
    days: params.days,
  );
});
