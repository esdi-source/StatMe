/// Settings Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/config/app_config.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import 'onboarding_screen.dart';
import 'settings/data_export_screen.dart';

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
      darkMode: false, // Dark Mode wurde entfernt
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

            // Erweiterte Anpassungen Section (NEU)
            Text(
              'Erweiterte Anpassungen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Passe Farben, Transparenz und Hintergrund an.',
              style: TextStyle(color: tokens.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildAdvancedCustomizationSection(themeState, tokens),
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

            // Data & Export Section
            Text(
              'Daten & Export',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.download, color: tokens.primary),
                    title: const Text('Daten exportieren'),
                    subtitle: const Text('Alle deine Daten als JSON herunterladen'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DataExportScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.cloud_done, color: tokens.success),
                    title: const Text('Cloud-Synchronisation'),
                    subtitle: const Text('Alle Daten werden automatisch gesichert'),
                    trailing: Icon(
                      Icons.check_circle,
                      color: tokens.success,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.security, color: tokens.info),
                    title: const Text('Datensicherheit'),
                    subtitle: const Text('End-to-End verschlüsselte Übertragung'),
                  ),
                ],
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
                  const ListTile(
                    leading: Icon(Icons.info),
                    title: Text('Version'),
                    trailing: Text('1.0.0'),
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
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Setup erneut starten'),
                    subtitle: const Text('Onboarding wiederholen'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _restartOnboarding(context),
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

  /// Setup erneut starten
  Future<void> _restartOnboarding(BuildContext context) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup erneut starten?'),
        content: const Text(
          'Das Onboarding wird erneut angezeigt. '
          'Du kannst deine Widgets und das Design neu konfigurieren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Neu starten'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Onboarding zurücksetzen (user-spezifisch)
      await ref.read(userOnboardingProvider(user.id).notifier).reset();
      
      // App neu laden
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ref.invalidate(userOnboardingProvider(user.id));
      }
    }
  }

  /// Erweiterte Anpassungen Widget
  Widget _buildAdvancedCustomizationSection(ThemeState themeState, DesignTokens tokens) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intensität Slider
            _buildIntensitySlider(themeState, tokens),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            
            // Benutzerdefinierte Farben
            _buildCustomColorsSection(themeState, tokens),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            
            // Widget-Transparenz
            _buildTransparencySlider(themeState, tokens),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            
            // Hintergrundbild
            _buildBackgroundImageSection(themeState, tokens),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIntensitySlider(ThemeState themeState, DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.gradient, size: 20, color: tokens.primary),
            const SizedBox(width: 8),
            Text(
              'Farbintensität',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(themeState.intensity * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: tokens.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: tokens.primary,
            inactiveTrackColor: tokens.divider,
            thumbColor: tokens.primary,
            overlayColor: tokens.primary.withOpacity(0.2),
          ),
          child: Slider(
            value: themeState.intensity,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) {
              ref.read(themeStateProvider.notifier).setIntensity(value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mild', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
            Text('Intensiv', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCustomColorsSection(ThemeState themeState, DesignTokens tokens) {
    final primaryColors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette, size: 20, color: tokens.primary),
            const SizedBox(width: 8),
            Text(
              'Eigene Hauptfarbe',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            const Spacer(),
            Switch(
              value: themeState.useCustomColors,
              onChanged: (value) {
                ref.read(themeStateProvider.notifier).setUseCustomColors(value);
              },
              activeThumbColor: tokens.primary,
            ),
          ],
        ),
        if (themeState.useCustomColors) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: primaryColors.map((color) {
              final isSelected = themeState.customPrimaryColor?.value == color.value;
              return GestureDetector(
                onTap: () {
                  ref.read(themeStateProvider.notifier).setCustomColors(primary: color);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
  
  Widget _buildTransparencySlider(ThemeState themeState, DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.opacity, size: 20, color: tokens.primary),
            const SizedBox(width: 8),
            Text(
              'Widget-Transparenz',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(themeState.widgetTransparency * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: tokens.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: tokens.primary,
            inactiveTrackColor: tokens.divider,
            thumbColor: tokens.primary,
            overlayColor: tokens.primary.withOpacity(0.2),
          ),
          child: Slider(
            value: themeState.widgetTransparency,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) {
              ref.read(themeStateProvider.notifier).setWidgetTransparency(value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Opak', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
            Text('Transparent', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildBackgroundImageSection(ThemeState themeState, DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image, size: 20, color: tokens.primary),
            const SizedBox(width: 8),
            Text(
              'Hintergrundbild',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (themeState.hasBackgroundImage) ...[
          // Vorschau des aktuellen Hintergrundbilds
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusMedium),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    themeState.backgroundImagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: tokens.surface,
                      child: Icon(Icons.broken_image, color: tokens.textSecondary, size: 48),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(themeStateProvider.notifier).clearBackgroundImage();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickBackgroundImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickBackgroundImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Kamera'),
              ),
            ),
          ],
        ),
        
        if (kIsWeb)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Tipp: Im Web können Bilder per URL eingefügt werden',
              style: TextStyle(fontSize: 11, color: tokens.textSecondary),
            ),
          ),
      ],
    );
  }
  
  Future<void> _pickBackgroundImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Für Web: base64 Data URL verwenden
        // Für Native: Dateipfad verwenden
        if (kIsWeb) {
          // final bytes = await image.readAsBytes();
          // final base64 = 'data:image/jpeg;base64,${Uri.encodeFull(String.fromCharCodes(bytes))}';
          ref.read(themeStateProvider.notifier).setBackgroundImage(image.path);
        } else {
          ref.read(themeStateProvider.notifier).setBackgroundImage(image.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bild konnte nicht geladen werden: $e')),
        );
      }
    }
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
