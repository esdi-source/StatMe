/// Settings Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../ui/theme/app_theme.dart';

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
  bool _darkMode = false;
  Color _selectedThemeColor = ThemeColor.sage.color;

  @override
  void initState() {
    super.initState();
    _waterGoalController = TextEditingController(text: '2500');
    _calorieGoalController = TextEditingController(text: '2000');
    _stepsGoalController = TextEditingController(text: '10000');
    _selectedThemeColor = ref.read(themeColorProvider);
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
          _darkMode = settings.darkMode;
          _selectedThemeColor = Color(settings.themeColorValue);
        });
        // Theme-Provider aktualisieren
        ref.read(themeColorProvider.notifier).state = Color(settings.themeColorValue);
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
      darkMode: _darkMode,
      themeColorValue: _selectedThemeColor.value,
    );

    await ref.read(settingsNotifierProvider.notifier).update(settings);
    
    // Theme-Provider aktualisieren
    ref.read(themeColorProvider.notifier).state = _selectedThemeColor;
    
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

  void _selectColor(ThemeColor themeColor) {
    setState(() {
      _selectedThemeColor = themeColor.color;
    });
    // Sofort das Theme aktualisieren für Live-Vorschau
    ref.read(themeColorProvider.notifier).state = themeColor.color;
  }

  Widget _buildColorSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pastell-Farben
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Pastell-Töne',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ThemeColor.lavender,
                ThemeColor.sage,
                ThemeColor.blush,
                ThemeColor.sky,
                ThemeColor.mint,
              ].map((themeColor) => _buildColorOption(themeColor)).toList(),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            // Erdtöne
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Erdtöne',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ThemeColor.caramel,
                ThemeColor.terracotta,
                ThemeColor.mocha,
                ThemeColor.sand,
                ThemeColor.olive,
              ].map((themeColor) => _buildColorOption(themeColor)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(ThemeColor themeColor) {
    final isSelected = _selectedThemeColor.value == themeColor.color.value;
    
    return GestureDetector(
      onTap: () => _selectColor(themeColor),
      child: Tooltip(
        message: '${themeColor.label}\n${themeColor.description}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 56 : 48,
          height: isSelected ? 56 : 48,
          decoration: BoxDecoration(
            color: themeColor.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.black54 : Colors.transparent,
              width: 3,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: themeColor.color.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  color: _getContrastColor(themeColor.color),
                  size: 28,
                )
              : null,
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    // Berechne die Helligkeit und wähle Schwarz oder Weiß
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;

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
                      backgroundColor: Colors.green.shade100,
                      child: Text(
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName![0].toUpperCase()
                            : user?.email[0].toUpperCase() ?? 'D',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          if (AppConfig.isDemoMode)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DEMO MODUS',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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

            // Theme Color Section
            Text(
              'Design-Farbe',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Wähle eine Farbe, die zu dir passt. Das gesamte App-Design wird daran angepasst.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildColorSelector(),
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
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.water_drop, color: Colors.white),
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
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.restaurant, color: Colors.white),
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
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.directions_walk, color: Colors.white),
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
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode),
                    title: const Text('Dunkler Modus'),
                    subtitle: const Text('Augen schonen'),
                    value: _darkMode,
                    onChanged: (value) {
                      setState(() => _darkMode = value);
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
                        color: AppConfig.isDemoMode ? Colors.blue : Colors.green,
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
                  foregroundColor: Colors.red,
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
}
