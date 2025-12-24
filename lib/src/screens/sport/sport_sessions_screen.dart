/// Sport Sessions Screen - Alle Sporteinheiten anzeigen und verwalten
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class SportSessionsScreen extends ConsumerStatefulWidget {
  const SportSessionsScreen({super.key});

  @override
  ConsumerState<SportSessionsScreen> createState() => _SportSessionsScreenState();
}

class _SportSessionsScreenState extends ConsumerState<SportSessionsScreen> {
  String? _filterSportType;
  
  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(designTokensProvider);
    final sessions = ref.watch(sportSessionsNotifierProvider);
    
    // Group sessions by date
    final groupedSessions = _groupSessionsByDate(sessions);
    
    // Get unique sport types for filter
    final sportTypes = sessions.map((s) => s.sportTypeName ?? 'Unbekannt').toSet().toList()..sort();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sporteinheiten'),
        actions: [
          if (sportTypes.isNotEmpty)
            PopupMenuButton<String?>(
              icon: Icon(
                Icons.filter_list,
                color: _filterSportType != null ? tokens.primary : null,
              ),
              onSelected: (value) {
                setState(() => _filterSportType = value);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('Alle anzeigen'),
                ),
                const PopupMenuDivider(),
                ...sportTypes.map((type) => PopupMenuItem(
                  value: type,
                  child: Text(type),
                )),
              ],
            ),
        ],
      ),
      body: sessions.isEmpty
          ? _buildEmptyState(tokens)
          : _buildSessionsList(tokens, groupedSessions),
    );
  }

  Map<String, List<SportSession>> _groupSessionsByDate(List<SportSession> sessions) {
    final filtered = _filterSportType != null
        ? sessions.where((s) => (s.sportTypeName ?? 'Unbekannt') == _filterSportType).toList()
        : sessions;
    
    final sorted = [...filtered]..sort((a, b) => b.date.compareTo(a.date));
    
    final Map<String, List<SportSession>> grouped = {};
    for (final session in sorted) {
      final key = DateFormat('yyyy-MM-dd').format(session.date);
      grouped.putIfAbsent(key, () => []).add(session);
    }
    
    return grouped;
  }

  Widget _buildEmptyState(DesignTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: tokens.textDisabled.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Einheiten gefunden',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(DesignTokens tokens, Map<String, List<SportSession>> grouped) {
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final sessions = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 16),
            _buildDateHeader(tokens, date, sessions),
            const SizedBox(height: 8),
            ...sessions.map((s) => _buildSessionCard(tokens, s)),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DesignTokens tokens, DateTime date, List<SportSession> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);
    
    String label;
    if (sessionDate == today) {
      label = 'Heute';
    } else if (sessionDate == today.subtract(const Duration(days: 1))) {
      label = 'Gestern';
    } else {
      label = DateFormat('EEEE, dd. MMMM', 'de_DE').format(date);
    }
    
    final totalDuration = sessions.fold<Duration>(
      Duration.zero, (sum, s) => sum + s.duration);
    final totalCalories = sessions.fold<int>(
      0, (sum, s) => sum + (s.caloriesBurned ?? 0));
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: tokens.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Row(
          children: [
            Icon(Icons.timer, size: 14, color: tokens.textDisabled),
            const SizedBox(width: 4),
            Text(
              _formatDuration(totalDuration),
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.local_fire_department, size: 14, color: tokens.textDisabled),
            const SizedBox(width: 4),
            Text(
              '$totalCalories kcal',
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionCard(DesignTokens tokens, SportSession session) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: tokens.error,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Einheit löschen?'),
            content: const Text('Diese Aktion kann nicht rückgängig gemacht werden.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Löschen'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(sportSessionsNotifierProvider.notifier).delete(session.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(color: tokens.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIntensityColor(tokens, session.intensity).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getSportIcon(session.sportTypeName ?? 'Unbekannt'),
                color: _getIntensityColor(tokens, session.intensity),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.sportTypeName ?? 'Unbekannt',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        DateFormat('HH:mm').format(session.date),
                        style: TextStyle(
                          color: tokens.textDisabled,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getIntensityColor(tokens, session.intensity).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          session.intensity.label,
                          style: TextStyle(
                            color: _getIntensityColor(tokens, session.intensity),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (session.notes != null && session.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      session.notes!,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDuration(session.duration),
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (session.caloriesBurned != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, size: 12, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        '${session.caloriesBurned} kcal',
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
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

  Color _getIntensityColor(DesignTokens tokens, SportIntensity intensity) {
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
}
