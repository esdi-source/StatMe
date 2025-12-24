/// Sport Haupt-Screen - Container für alle Sport Sub-Widgets
/// 
/// Übersicht über:
/// - Aktuelle Streak
/// - Wöchentliche Zusammenfassung
/// - Letzte Sporteinheiten
/// - Gewichtstrend
/// - Schnellzugriff auf alle Bereiche
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'sport_sessions_screen.dart';
import 'weight_screen.dart';
import 'sport_stats_screen.dart';
import 'sport_timer_screen.dart';
import 'exercises_screen.dart';
import 'workout_plans_screen.dart';
import 'muscle_analysis_screen.dart';

class SportScreen extends ConsumerStatefulWidget {
  const SportScreen({super.key});

  @override
  ConsumerState<SportScreen> createState() => _SportScreenState();
}

class _SportScreenState extends ConsumerState<SportScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    await Future.wait([
      ref.read(sportSessionsNotifierProvider.notifier).load(user.id),
      ref.read(weightNotifierProvider.notifier).load(user.id),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final sessions = ref.watch(sportSessionsNotifierProvider);
    final weights = ref.watch(weightNotifierProvider);
    final streak = ref.watch(sportStreakProvider);
    final stats = ref.watch(sportStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.fitness_center, color: tokens.primary),
            const SizedBox(width: 8),
            const Text('Sport'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer),
            onPressed: () => _navigateTo(const SportTimerScreen()),
            tooltip: 'Timer starten',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSessionDialog(),
            tooltip: 'Einheit hinzufügen',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: sessions.isEmpty && weights.isEmpty
            ? _buildEmptyState(tokens)
            : _buildContent(tokens, sessions, weights, streak, stats),
      ),
    );
  }

  Widget _buildEmptyState(DesignTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: tokens.textDisabled.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Noch keine Sportdaten',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Starte deine erste Sporteinheit oder füge eine manuell hinzu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _navigateTo(const SportTimerScreen()),
                  icon: const Icon(Icons.timer),
                  label: const Text('Timer starten'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _showAddSessionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Manuell'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    DesignTokens tokens,
    List<SportSession> sessions,
    List<WeightEntry> weights,
    SportStreak streak,
    List<SportStats> stats,
  ) {
    final now = DateTime.now();
    final todaySessions = sessions.where((s) =>
      s.date.year == now.year &&
      s.date.month == now.month &&
      s.date.day == now.day).toList();
    
    final recentSessions = [...sessions]
      ..sort((a, b) => b.date.compareTo(a.date));
    
    final weeklyDuration = ref.read(sportSessionsNotifierProvider.notifier).getTotalDurationForWeek();
    final weeklyCalories = ref.read(sportSessionsNotifierProvider.notifier).getTotalCaloriesForWeek();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Streak und Wöchentliche Stats
        _buildWeeklyOverview(tokens, streak, weeklyDuration, weeklyCalories, todaySessions.length),
        const SizedBox(height: 16),
        
        // Quick Actions
        _buildQuickActions(tokens),
        const SizedBox(height: 16),
        
        // Heutige Einheiten
        if (todaySessions.isNotEmpty) ...[
          _buildTodaySessions(tokens, todaySessions),
          const SizedBox(height: 16),
        ],
        
        // Gewichtstrend
        if (weights.isNotEmpty) ...[
          _buildWeightCard(tokens, weights),
          const SizedBox(height: 16),
        ],
        
        // Top Sportarten
        if (stats.isNotEmpty) ...[
          _buildTopSports(tokens, stats),
          const SizedBox(height: 16),
        ],
        
        // Letzte Einheiten
        if (recentSessions.isNotEmpty) ...[
          _buildRecentSessions(tokens, recentSessions.take(5).toList()),
        ],
      ],
    );
  }

  Widget _buildWeeklyOverview(
    DesignTokens tokens,
    SportStreak streak,
    Duration weeklyDuration,
    int weeklyCalories,
    int todayCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tokens.primary.withOpacity(0.8),
            tokens.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diese Woche',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(weeklyDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${streak.currentStreak} Tage',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatChip(Icons.bolt, '$weeklyCalories kcal', Colors.white),
              const SizedBox(width: 12),
              _buildStatChip(Icons.today, '$todayCount heute', Colors.white),
              const SizedBox(width: 12),
              _buildStatChip(Icons.emoji_events, 'Best: ${streak.longestStreak}', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(DesignTokens tokens) {
    return Column(
      children: [
        // Erste Reihe - Original Actions
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                tokens,
                Icons.list_alt,
                'Einheiten',
                'Alle anzeigen',
                () => _navigateTo(const SportSessionsScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                tokens,
                Icons.monitor_weight,
                'Gewicht',
                'Verlauf',
                () => _navigateTo(const WeightScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                tokens,
                Icons.bar_chart,
                'Statistik',
                'Übersicht',
                () => _navigateTo(const SportStatsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Zweite Reihe - Neue Actions
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                tokens,
                Icons.fitness_center,
                'Übungen',
                'Datenbank',
                () => _navigateTo(const ExercisesScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                tokens,
                Icons.calendar_month,
                'Pläne',
                'Training',
                () => _navigateTo(const WorkoutPlansScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                tokens,
                Icons.analytics,
                'Muskeln',
                'Analyse',
                () => _navigateTo(const MuscleAnalysisScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    DesignTokens tokens,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(color: tokens.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: tokens.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: tokens.textDisabled,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySessions(DesignTokens tokens, List<SportSession> sessions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, color: tokens.success, size: 20),
              const SizedBox(width: 8),
              Text(
                'Heute',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(),
          ...sessions.map((s) => _buildSessionTile(tokens, s, compact: true)),
        ],
      ),
    );
  }

  Widget _buildWeightCard(DesignTokens tokens, List<WeightEntry> weights) {
    final latest = ref.read(weightNotifierProvider.notifier).latest;
    final trend = ref.read(weightNotifierProvider.notifier).getTrend();
    
    return GestureDetector(
      onTap: () => _navigateTo(const WeightScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(color: tokens.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.monitor_weight, color: tokens.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gewicht',
                    style: TextStyle(
                      color: tokens.textDisabled,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    latest != null ? '${latest.weightKg.toStringAsFixed(1)} kg' : '-',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            if (trend != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trend < 0 ? tokens.success.withOpacity(0.1) : tokens.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      trend < 0 ? Icons.trending_down : Icons.trending_up,
                      color: trend < 0 ? tokens.success : tokens.error,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trend.abs().toStringAsFixed(1)} kg',
                      style: TextStyle(
                        color: trend < 0 ? tokens.success : tokens.error,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            Icon(Icons.chevron_right, color: tokens.textDisabled),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSports(DesignTokens tokens, List<SportStats> stats) {
    final topStats = stats.take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Sportarten',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () => _navigateTo(const SportStatsScreen()),
                child: const Text('Alle'),
              ),
            ],
          ),
          const Divider(),
          ...topStats.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;
            return _buildTopSportTile(tokens, stat, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildTopSportTile(DesignTokens tokens, SportStats stat, int rank) {
    final icon = _getSportIcon(stat.sportType);
    final color = [tokens.primary, tokens.secondary, tokens.info][rank - 1];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: tokens.textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stat.sportType,
              style: TextStyle(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            _formatDuration(stat.totalDuration),
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(DesignTokens tokens, List<SportSession> sessions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Letzte Einheiten',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () => _navigateTo(const SportSessionsScreen()),
                child: const Text('Alle'),
              ),
            ],
          ),
          const Divider(),
          ...sessions.map((s) => _buildSessionTile(tokens, s)),
        ],
      ),
    );
  }

  Widget _buildSessionTile(DesignTokens tokens, SportSession session, {bool compact = false}) {
    final icon = _getSportIcon(session.sportType);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getIntensityColor(session.intensity).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _getIntensityColor(session.intensity), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.sportType,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!compact)
                  Text(
                    DateFormat('dd.MM.yyyy, HH:mm').format(session.date),
                    style: TextStyle(
                      color: tokens.textDisabled,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDuration(session.duration),
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              if (session.caloriesBurned != null)
                Text(
                  '${session.caloriesBurned} kcal',
                  style: TextStyle(
                    color: tokens.textDisabled,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getSportIcon(String sportType) {
    final type = sportType.toLowerCase();
    if (type.contains('lauf') || type.contains('jogg') || type.contains('run')) {
      return Icons.directions_run;
    } else if (type.contains('rad') || type.contains('bike') || type.contains('cycl')) {
      return Icons.directions_bike;
    } else if (type.contains('schwimm') || type.contains('swim')) {
      return Icons.pool;
    } else if (type.contains('yoga') || type.contains('stretch')) {
      return Icons.self_improvement;
    } else if (type.contains('kraft') || type.contains('weight') || type.contains('gym')) {
      return Icons.fitness_center;
    } else if (type.contains('walk') || type.contains('spazier') || type.contains('geh')) {
      return Icons.directions_walk;
    } else if (type.contains('fußball') || type.contains('soccer') || type.contains('football')) {
      return Icons.sports_soccer;
    } else if (type.contains('basketball')) {
      return Icons.sports_basketball;
    } else if (type.contains('tennis')) {
      return Icons.sports_tennis;
    }
    return Icons.fitness_center;
  }

  Color _getIntensityColor(SportIntensity intensity) {
    final tokens = ref.read(designTokensProvider);
    switch (intensity) {
      case SportIntensity.low:
        return tokens.info;
      case SportIntensity.low:
        return tokens.success;
      case SportIntensity.medium:
        return tokens.warning;
      case SportIntensity.high:
        return Colors.orange;
      case SportIntensity.extreme:
        return tokens.error;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes min';
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showAddSessionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSportSessionSheet(),
    );
  }
}

// ============================================
// ADD SESSION BOTTOM SHEET
// ============================================

class AddSportSessionSheet extends ConsumerStatefulWidget {
  const AddSportSessionSheet({super.key});

  @override
  ConsumerState<AddSportSessionSheet> createState() => _AddSportSessionSheetState();
}

class _AddSportSessionSheetState extends ConsumerState<AddSportSessionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _sportTypeController = TextEditingController();
  final _notesController = TextEditingController();
  
  SportIntensity _intensity = SportIntensity.medium;
  Duration _duration = const Duration(minutes: 30);
  DateTime _date = DateTime.now();
  
  final List<String> _commonSports = [
    'Laufen', 'Radfahren', 'Schwimmen', 'Krafttraining', 
    'Yoga', 'Spazieren', 'Wandern', 'HIIT', 'Tanzen', 'Fußball',
  ];

  @override
  void dispose() {
    _sportTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.textDisabled.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sporteinheit hinzufügen',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Sportart
                TextFormField(
                  controller: _sportTypeController,
                  decoration: InputDecoration(
                    labelText: 'Sportart',
                    hintText: 'z.B. Laufen, Krafttraining...',
                    prefixIcon: const Icon(Icons.fitness_center),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte Sportart eingeben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Quick select sports
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonSports.map((sport) {
                    final isSelected = _sportTypeController.text == sport;
                    return FilterChip(
                      label: Text(sport),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _sportTypeController.text = sport;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                
                // Dauer
                Text(
                  'Dauer: ${_formatDuration(_duration)}',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Slider(
                  value: _duration.inMinutes.toDouble(),
                  min: 5,
                  max: 180,
                  divisions: 35,
                  label: _formatDuration(_duration),
                  onChanged: (value) {
                    setState(() {
                      _duration = Duration(minutes: value.round());
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Intensität
                Text(
                  'Intensität',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: SportIntensity.values.map((intensity) {
                    final isSelected = _intensity == intensity;
                    return GestureDetector(
                      onTap: () => setState(() => _intensity = intensity),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? tokens.primary.withOpacity(0.2)
                                  : tokens.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? tokens.primary : tokens.divider,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              intensity.label,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            intensity.label,
                            style: TextStyle(
                              color: isSelected ? tokens.primary : tokens.textSecondary,
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                
                // Datum
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, color: tokens.primary),
                  title: Text(DateFormat('dd.MM.yyyy, HH:mm').format(_date)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectDateTime,
                ),
                const SizedBox(height: 12),
                
                // Notizen
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notizen (optional)',
                    hintText: 'Wie hat es sich angefühlt?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMedium),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Speichern Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSession,
                    child: const Text('Speichern'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes min';
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_date),
      );
      
      if (time != null) {
        setState(() {
          _date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    // Estimate calories based on duration and intensity
    final caloriesPerMinute = _intensity.calorieMultiplier * 3.5 * 70 / 200; // Assuming 70kg
    final calories = (caloriesPerMinute * _duration.inMinutes).round();
    
    final session = SportSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.id,
      sportType: _sportTypeController.text,
      duration: _duration,
      intensity: _intensity,
      caloriesBurned: calories,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      date: _date,
      createdAt: DateTime.now(),
    );
    
    await ref.read(sportSessionsNotifierProvider.notifier).add(session);
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sporteinheit gespeichert!')),
      );
    }
  }
}
