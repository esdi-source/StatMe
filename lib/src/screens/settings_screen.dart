/// Settings Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../ui/theme/app_theme.dart';
import '../ui/theme/design_tokens.dart';
import '../ui/theme/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _waterGoalController;
  late TextEditingController _calorieGoalController;
  late TextEditingController _stepsGoalController;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _waterGoalController = TextEditingController(text: '2500');
    _calorieGoalController = TextEditingController(text: '2000');
    _stepsGoalController = TextEditingController(text: '10000');
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user != null) {
      await ref.read(settingsNotifierProvider.notifier).load(user.id);
      final settings = ref.read(settingsNotifierProvider);
      if (settings != null) {
        setState(() {
          _waterGoalController.text = settings.dailyWaterGoalMl.toString();
          _calorieGoalController.text = settings.dailyCalorieGoal.toString();
          _stepsGoalController.text = settings.dailyStepsGoal.toString();
          _notificationsEnabled = settings.notificationsEnabled;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final currentSettings = ref.read(settingsNotifierProvider);
    
    final settings = SettingsModel(
      id: currentSettings?.id ?? user.id,
      userId: user.id,
      dailyWaterGoalMl: int.tryParse(_waterGoalController.text) ?? 2500,
      dailyCalorieGoal: int.tryParse(_calorieGoalController.text) ?? 2000,
      dailyStepsGoal: int.tryParse(_stepsGoalController.text) ?? 10000,
      notificationsEnabled: _notificationsEnabled,
      darkMode: ref.read(themePresetProvider) == ThemePreset.dark,
      themeColorValue: ref.read(designTokensProvider).primary.value,
    );

    await ref.read(settingsNotifierProvider.notifier).update(settings);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Einstellungen gespeichert')),
      );
    }
  }

  @override
  void dispose() {
    _waterGoalController.dispose();
    _calorieGoalController.dispose();
    _stepsGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final themeState = ref.watch(themeStateProvider);
    final tokens = ref.watch(designTokensProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: tokens.primary.withOpacity(0.2),
                      child: Text(
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName![0].toUpperCase()
                            : user?.email[0].toUpperCase() ?? 'D',
                        style: TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.bold,
                          color: tokens.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Demo Benutzer',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            user?.email ?? 'demo@statme.app',
                            style: TextStyle(color: tokens.textSecondary),
                          ),
                          if (AppConfig.isDemoMode)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: tokens.info.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(tokens.radiusSmall),
                              ),
                              child: Text(
                                'DEMO MODUS',
                                style: TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold,
                                  color: tokens.info,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Theme Preset Section (NEU)
            Text(
              'Design-Stil',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Wähle einen Stil für das gesamte App-Design.',
              style: TextStyle(color: tokens.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildThemePresetSelector(themeState, tokens),
            const SizedBox(height: 24),

            // Shape Style Section (NEU)
            Text(
              'Form-Stil',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Wähle zwischen runden oder eckigen Ecken.',
              style: TextStyle(color: tokens.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildShapeStyleSelector(themeState, tokens),
            const SizedBox(height: 24),

            // Daily Goals Section
            Text(
              'Tagesziele',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Water Goal
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tokens.info,
                        child: const Icon(Icons.water_drop, color: Colors.white),
                      ),
                      title: const Text('Wasser-Ziel'),
                      subtitle: const Text('Tägliches Wasserziel in ml'),
                      trailing: SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _waterGoalController,
                          decoration: const InputDecoration(
                            suffixText: 'ml',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const Divider(),
                    // Calorie Goal
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tokens.warning,
                        child: const Icon(Icons.restaurant, color: Colors.white),
                      ),
                      title: const Text('Kalorien-Ziel'),
                      subtitle: const Text('Tägliche Kalorienaufnahme'),
                      trailing: SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _calorieGoalController,
                          decoration: const InputDecoration(
                            suffixText: 'kcal',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const Divider(),
                    // Steps Goal
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tokens.success,
                        child: const Icon(Icons.directions_walk, color: Colors.white),
                      ),
                      title: const Text('Schritte-Ziel'),
                      subtitle: const Text('Tägliche Schritte'),
                      trailing: SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _stepsGoalController,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Preferences Section
            Text(
              'Einstellungen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications),
                    title: const Text('Benachrichtigungen'),
                    subtitle: const Text('Erinnerungen aktivieren'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('Einstellungen speichern'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Info Section
            Text(
              'Über die App',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Version'),
                    trailing: const Text('1.0.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('Modus'),
                    trailing: Text(
                      AppConfig.isDemoMode ? 'Demo' : 'Produktion',
                      style: TextStyle(
                        color: AppConfig.isDemoMode ? tokens.info : tokens.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.storage),
                    title: const Text('Datenspeicherung'),
                    trailing: Text(
                      AppConfig.isDemoMode ? 'Lokal (In-Memory)' : 'Cloud (Supabase)',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Abmelden'),
                      content: const Text('Möchtest du dich wirklich abmelden?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Abbrechen'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Abmelden'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref.read(authNotifierProvider.notifier).signOut();
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Abmelden'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.error,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Theme-Preset Auswahl Widget
  Widget _buildThemePresetSelector(ThemeState themeState, DesignTokens tokens) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Grid mit 6 Theme-Presets
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: ThemePreset.values.map((preset) {
                final isSelected = themeState.preset == preset;
                final previewTokens = DesignTokens.forPreset(preset, themeState.shape);
                
                return GestureDetector(
                  onTap: () {
                    ref.read(themeStateProvider.notifier).setPreset(preset);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: previewTokens.surface,
                      borderRadius: BorderRadius.circular(tokens.radiusMedium),
                      border: Border.all(
                        color: isSelected ? previewTokens.primary : previewTokens.divider,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? previewTokens.shadowSmall : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Farbkreise als Preview
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: previewTokens.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: previewTokens.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          preset.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: previewTokens.textPrimary,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: previewTokens.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Beschreibung des aktuellen Themes
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.background,
                borderRadius: BorderRadius.circular(tokens.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: tokens.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      themeState.preset.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shape-Style Auswahl Widget
  Widget _buildShapeStyleSelector(ThemeState themeState, DesignTokens tokens) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: ShapeStyle.values.map((shape) {
            final isSelected = themeState.shape == shape;
            
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(themeStateProvider.notifier).setShape(shape);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? tokens.primary.withOpacity(0.1) : tokens.surface,
                    borderRadius: BorderRadius.circular(
                      shape == ShapeStyle.round ? 16 : 4,
                    ),
                    border: Border.all(
                      color: isSelected ? tokens.primary : tokens.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Preview Shape
                      Container(
                        width: 48,
                        height: 32,
                        decoration: BoxDecoration(
                          color: tokens.primary,
                          borderRadius: BorderRadius.circular(
                            shape == ShapeStyle.round ? 8 : 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        shape.label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? tokens.primary : tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shape.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: tokens.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
