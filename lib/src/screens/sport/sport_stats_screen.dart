/// Sport Stats Screen - Statistiken und Übersicht nach Sportart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class SportStatsScreen extends ConsumerWidget {
  const SportStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(designTokensProvider);
    final stats = ref.watch(sportStatsProvider);
    final streak = ref.watch(sportStreakProvider);
    final sessions = ref.watch(sportSessionsNotifierProvider);
    
    // Calculate overall stats
    final totalSessions = sessions.length;
    final totalDuration = sessions.fold<Duration>(
      Duration.zero, (sum, s) => sum + s.duration);
    final totalCalories = sessions.fold<int>(
      0, (sum, s) => sum + (s.caloriesBurned ?? 0));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
      ),
      body: sessions.isEmpty
          ? _buildEmptyState(tokens)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Overall stats
                _buildOverallStats(tokens, totalSessions, totalDuration, totalCalories, streak),
                const SizedBox(height: 16),
                
                // Activity by weekday
                _buildWeekdayStats(tokens, sessions),
                const SizedBox(height: 16),
                
                // Stats by sport type
                _buildSportTypeStats(tokens, stats),
              ],
            ),
    );
  }

  Widget _buildEmptyState(DesignTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 64,
            color: tokens.textDisabled.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Noch keine Statistiken',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Füge Sporteinheiten hinzu,\num Statistiken zu sehen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tokens.textDisabled,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats(
    DesignTokens tokens,
    int totalSessions,
    Duration totalDuration,
    int totalCalories,
    SportStreak streak,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tokens.primary.withOpacity(0.8),
            tokens.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gesamt',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Einheiten', '$totalSessions', Icons.fitness_center),
              _buildStatColumn('Zeit', _formatDuration(totalDuration), Icons.timer),
              _buildStatColumn('Kalorien', '$totalCalories', Icons.local_fire_department),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Aktuelle Serie: ${streak.currentStreak} Tage',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Beste: ${streak.longestStreak} Tage',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayStats(DesignTokens tokens, List<SportSession> sessions) {
    final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final Map<int, int> countByDay = {};
    
    for (final session in sessions) {
      final day = session.date.weekday;
      countByDay[day] = (countByDay[day] ?? 0) + 1;
    }
    
    final maxCount = countByDay.values.isEmpty 
        ? 1 
        : countByDay.values.reduce((a, b) => a > b ? a : b);
    
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
          Text(
            'Aktivität nach Wochentag',
            style: TextStyle(
              color: tokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final dayNum = index + 1;
              final count = countByDay[dayNum] ?? 0;
              final height = maxCount > 0 ? (count / maxCount) * 80 : 0.0;
              
              return Column(
                children: [
                  SizedBox(
                    height: 80,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (count > 0)
                          Text(
                            '$count',
                            style: TextStyle(
                              color: tokens.textDisabled,
                              fontSize: 10,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          width: 28,
                          height: height.clamp(4.0, 80.0),
                          decoration: BoxDecoration(
                            color: count > 0 ? tokens.primary : tokens.divider,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weekdays[index],
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSportTypeStats(DesignTokens tokens, List<SportStats> stats) {
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
          Text(
            'Nach Sportart',
            style: TextStyle(
              color: tokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(),
          ...stats.map((stat) => _buildSportTypeTile(tokens, stat, stats)),
        ],
      ),
    );
  }

  Widget _buildSportTypeTile(DesignTokens tokens, SportStats stat, List<SportStats> allStats) {
    final totalDuration = allStats.fold<Duration>(
      Duration.zero, (sum, s) => sum + s.totalDuration);
    final percentage = totalDuration.inMinutes > 0 
        ? (stat.totalDuration.inMinutes / totalDuration.inMinutes * 100)
        : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_getSportIcon(stat.sportType), color: tokens.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.sportType,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${stat.sessionCount} Einheiten',
                      style: TextStyle(
                        color: tokens.textDisabled,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDuration(stat.totalDuration),
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${stat.totalCalories} kcal',
                    style: TextStyle(
                      color: tokens.textDisabled,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: tokens.divider,
              valueColor: AlwaysStoppedAnimation(tokens.primary),
              minHeight: 6,
            ),
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
    }
    return Icons.fitness_center;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes min';
  }
}
