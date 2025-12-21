/// Muskelanalyse Screen
/// 
/// Zeigt Trainingsbalance über alle Muskelgruppen:
/// - Untertrainierte Muskeln
/// - Übertrainierte Muskeln
/// - Ausgewogene Muskeln
/// - Empfehlungen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/sport_model.dart';

class MuscleAnalysisScreen extends ConsumerWidget {
  const MuscleAnalysisScreen({super.key});

  static const _muscleInfo = <String, (String, IconData, String)>{
    'chest': ('Brust', Icons.accessibility_new, '💪'),
    'shoulders': ('Schultern', Icons.accessibility, '🎯'),
    'triceps': ('Trizeps', Icons.fitness_center, '💪'),
    'back': ('Rücken', Icons.airline_seat_recline_normal, '🔙'),
    'lats': ('Latissimus', Icons.height, '🔙'),
    'biceps': ('Bizeps', Icons.sports_martial_arts, '💪'),
    'quads': ('Quadrizeps', Icons.directions_run, '🦵'),
    'hamstrings': ('Beinbizeps', Icons.directions_walk, '🦵'),
    'glutes': ('Gesäß', Icons.chair, '🍑'),
    'calves': ('Waden', Icons.snowboarding, '🦵'),
    'abs': ('Bauch', Icons.grid_view, '🎯'),
    'obliques': ('Schräge Bauchmuskeln', Icons.rotate_right, '🎯'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(designTokensProvider);
    final analysis = ref.watch(muscleAnalysisProvider);
    final plans = ref.watch(workoutPlansNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Muskelanalyse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context, tokens),
          ),
        ],
      ),
      body: plans.isEmpty
          ? _buildEmptyState(tokens)
          : _buildAnalysis(tokens, analysis),
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
              Icons.analytics_outlined,
              size: 80,
              color: tokens.textDisabled.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Keine Daten',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Erstelle Trainingspläne um deine Muskelbalance zu analysieren.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysis(DesignTokens tokens, MuscleAnalysis analysis) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Übersicht
        _buildOverviewCard(tokens, analysis),
        const SizedBox(height: 16),
        
        // Untertrainiert
        if (analysis.undertrained.isNotEmpty) ...[
          _buildSectionHeader(tokens, '⚠️ Untertrainiert', Colors.orange),
          const SizedBox(height: 8),
          _buildMuscleGrid(tokens, analysis.undertrained, Colors.orange),
          const SizedBox(height: 16),
        ],
        
        // Übertrainiert
        if (analysis.overtrained.isNotEmpty) ...[
          _buildSectionHeader(tokens, '🔥 Übertrainiert', Colors.red),
          const SizedBox(height: 8),
          _buildMuscleGrid(tokens, analysis.overtrained, Colors.red),
          const SizedBox(height: 16),
        ],
        
        // Ausgewogen
        if (analysis.balanced.isNotEmpty) ...[
          _buildSectionHeader(tokens, '✅ Ausgewogen', Colors.green),
          const SizedBox(height: 8),
          _buildMuscleGrid(tokens, analysis.balanced, Colors.green),
          const SizedBox(height: 16),
        ],
        
        // Empfehlungen
        _buildRecommendations(tokens, analysis),
      ],
    );
  }

  Widget _buildOverviewCard(DesignTokens tokens, MuscleAnalysis analysis) {
    final total = analysis.undertrained.length + 
                  analysis.overtrained.length + 
                  analysis.balanced.length;
    
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
            children: [
              const Icon(Icons.analytics, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Balance-Score',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_calculateScore(analysis)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMiniStat('✅', analysis.balanced.length, total, Colors.white),
                  _buildMiniStat('⚠️', analysis.undertrained.length, total, Colors.orange.shade200),
                  _buildMiniStat('🔥', analysis.overtrained.length, total, Colors.red.shade200),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String emoji, int count, int total, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          '$count/$total',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  int _calculateScore(MuscleAnalysis analysis) {
    final total = analysis.undertrained.length + 
                  analysis.overtrained.length + 
                  analysis.balanced.length;
    if (total == 0) return 0;
    
    // Balanced = 100%, Undertrained = 50%, Overtrained = 30%
    final score = (analysis.balanced.length * 100 +
                   analysis.undertrained.length * 50 +
                   analysis.overtrained.length * 30) / total;
    return score.round();
  }

  Widget _buildSectionHeader(DesignTokens tokens, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: tokens.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleGrid(DesignTokens tokens, List<String> muscles, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: muscles.map((muscleId) {
        final info = _muscleInfo[muscleId];
        if (info == null) return const SizedBox.shrink();
        
        final (name, _, emoji) = info;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji),
              const SizedBox(width: 6),
              Text(
                name,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendations(DesignTokens tokens, MuscleAnalysis analysis) {
    final recommendations = <String>[];
    
    if (analysis.undertrained.isNotEmpty) {
      final muscles = analysis.undertrained
          .take(3)
          .map((m) => _muscleInfo[m]?.$1 ?? m)
          .join(', ');
      recommendations.add('💡 Füge mehr Übungen für $muscles hinzu');
    }
    
    if (analysis.overtrained.isNotEmpty) {
      final muscles = analysis.overtrained
          .take(2)
          .map((m) => _muscleInfo[m]?.$1 ?? m)
          .join(', ');
      recommendations.add('⚡ Reduziere Volumen für $muscles');
    }
    
    if (analysis.balanced.length > 6) {
      recommendations.add('🎉 Dein Training ist gut ausbalanciert!');
    }
    
    // Spezifische Empfehlungen
    if (analysis.undertrained.contains('legs') || 
        analysis.undertrained.contains('quads') || 
        analysis.undertrained.contains('hamstrings')) {
      recommendations.add('🦵 Leg Day nicht vergessen!');
    }
    
    if (analysis.overtrained.contains('chest') && 
        analysis.undertrained.contains('back')) {
      recommendations.add('🔄 Push/Pull-Balance überprüfen');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('📊 Erstelle mehr Trainingspläne für bessere Analyse');
    }
    
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
              Icon(Icons.lightbulb, color: tokens.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Empfehlungen',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              rec,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 14,
              ),
            ),
          )),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, DesignTokens tokens) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Über die Analyse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Die Muskelanalyse basiert auf deinen Trainingsplänen und zeigt:',
              style: TextStyle(color: tokens.textSecondary),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Text('✅', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Expanded(child: Text('Ausgewogen: Optimale Trainingsfrequenz')),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Text('⚠️', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Expanded(child: Text('Untertrainiert: Weniger als 30% des Durchschnitts')),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Text('🔥', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Expanded(child: Text('Übertrainiert: Mehr als 70% über Durchschnitt')),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Primäre Muskelgruppen zählen doppelt so viel wie sekundäre.',
              style: TextStyle(color: tokens.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }
}
