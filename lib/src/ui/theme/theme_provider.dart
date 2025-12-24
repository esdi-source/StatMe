/// Theme Provider für globales Theme-Management
/// 
/// Verwaltet:
/// - Aktuelles Theme-Preset (Fotzig, Modern, Minimal, Dark, Hell)
/// - Aktuelle Shape-Style (Rund, Eckig)
/// - Intensität der Farben (0.0 - 1.0)
/// - Benutzerdefinierte Farben
/// - Persistente Speicherung mit SharedPreferences
/// - Live-Updates an alle Widgets
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_tokens.dart';

// ============================================================================
// STORAGE KEYS
// ============================================================================

const String _themePresetKey = 'theme_preset_v2';
const String _shapeStyleKey = 'shape_style_v2';
const String _intensityKey = 'theme_intensity';
const String _customPrimaryKey = 'custom_primary_color';
const String _customSecondaryKey = 'custom_secondary_color';
const String _useCustomColorsKey = 'use_custom_colors';
const String _backgroundImagePathKey = 'background_image_path';
const String _customTextColorKey = 'custom_text_color';
const String _widgetTransparencyKey = 'widget_transparency';

// ============================================================================
// THEME STATE
// ============================================================================

/// Kombinierter Theme State mit erweiterten Optionen
class ThemeState {
  final ThemePreset preset;
  final ShapeStyle shape;
  final double intensity; // 0.0 (mild) - 1.0 (intensiv)
  final Color? customPrimaryColor;
  final Color? customSecondaryColor;
  final bool useCustomColors;
  final String? backgroundImagePath; // Pfad zum Hintergrundbild
  final Color? customTextColor; // Benutzerdefinierte Textfarbe
  final double widgetTransparency; // 0.0 (opak) - 1.0 (transparent)
  
  const ThemeState({
    this.preset = ThemePreset.hell,
    this.shape = ShapeStyle.round,
    this.intensity = 0.7, // Standard: 70%
    this.customPrimaryColor,
    this.customSecondaryColor,
    this.useCustomColors = false,
    this.backgroundImagePath,
    this.customTextColor,
    this.widgetTransparency = 0.0, // Standard: opak
  });
  
  /// Ob ein Hintergrundbild gesetzt ist
  bool get hasBackgroundImage => backgroundImagePath != null && backgroundImagePath!.isNotEmpty;
  
  ThemeState copyWith({
    ThemePreset? preset,
    ShapeStyle? shape,
    double? intensity,
    Color? customPrimaryColor,
    Color? customSecondaryColor,
    bool? useCustomColors,
    String? backgroundImagePath,
    Color? customTextColor,
    double? widgetTransparency,
    bool clearBackgroundImage = false,
    bool clearTextColor = false,
  }) {
    return ThemeState(
      preset: preset ?? this.preset,
      shape: shape ?? this.shape,
      intensity: intensity ?? this.intensity,
      customPrimaryColor: customPrimaryColor ?? this.customPrimaryColor,
      customSecondaryColor: customSecondaryColor ?? this.customSecondaryColor,
      useCustomColors: useCustomColors ?? this.useCustomColors,
      backgroundImagePath: clearBackgroundImage ? null : (backgroundImagePath ?? this.backgroundImagePath),
      customTextColor: clearTextColor ? null : (customTextColor ?? this.customTextColor),
      widgetTransparency: widgetTransparency ?? this.widgetTransparency,
    );
  }
  
  /// Aktualisiert die globalen Design Tokens
  void applyToTokens() {
    DesignTokens.setPreset(preset);
    DesignTokens.setShape(shape);
    DesignTokens.setIntensity(intensity);
    if (useCustomColors && customPrimaryColor != null) {
      DesignTokens.setCustomColors(customPrimaryColor, customSecondaryColor);
    } else {
      DesignTokens.clearCustomColors();
    }
  }
  
  /// Gibt die aktuellen Design Tokens zurück
  DesignTokens get tokens => DesignTokens.forPreset(
    preset, 
    shape,
    intensity: intensity,
    customPrimary: useCustomColors ? customPrimaryColor : null,
    customSecondary: useCustomColors ? customSecondaryColor : null,
  );
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          runtimeType == other.runtimeType &&
          preset == other.preset &&
          shape == other.shape &&
          intensity == other.intensity &&
          customPrimaryColor == other.customPrimaryColor &&
          customSecondaryColor == other.customSecondaryColor &&
          useCustomColors == other.useCustomColors &&
          backgroundImagePath == other.backgroundImagePath &&
          customTextColor == other.customTextColor &&
          widgetTransparency == other.widgetTransparency;
  
  @override
  int get hashCode => Object.hash(
    preset, shape, intensity, customPrimaryColor, customSecondaryColor, 
    useCustomColors, backgroundImagePath, customTextColor, widgetTransparency,
  );
}

// ============================================================================
// THEME NOTIFIER
// ============================================================================

/// StateNotifier für Theme-Management mit erweiterten Features
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadFromPrefs();
  }
  
  /// Lädt das Theme aus SharedPreferences
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Preset laden (Migration von alten Keys)
      var presetIndex = prefs.getInt(_themePresetKey);
      if (presetIndex == null) {
        // Migration von altem Key
        final oldPresetIndex = prefs.getInt('theme_preset');
        if (oldPresetIndex != null) {
          // Glass (index 1) wurde entfernt, also verschieben
          presetIndex = oldPresetIndex >= 1 ? oldPresetIndex - 1 : oldPresetIndex;
          if (presetIndex < 0) presetIndex = 0;
        }
      }
      
      final shapeIndex = prefs.getInt(_shapeStyleKey) ?? prefs.getInt('shape_style');
      final intensity = prefs.getDouble(_intensityKey) ?? 0.7;
      final useCustom = prefs.getBool(_useCustomColorsKey) ?? false;
      final widgetTransparency = prefs.getDouble(_widgetTransparencyKey) ?? 0.0;
      final backgroundImagePath = prefs.getString(_backgroundImagePathKey);
      
      // Custom Colors laden
      Color? customPrimary;
      Color? customSecondary;
      Color? customTextColor;
      
      final primaryValue = prefs.getInt(_customPrimaryKey);
      final secondaryValue = prefs.getInt(_customSecondaryKey);
      final textColorValue = prefs.getInt(_customTextColorKey);
      
      if (primaryValue != null) {
        customPrimary = Color(primaryValue);
      }
      if (secondaryValue != null) {
        customSecondary = Color(secondaryValue);
      }
      if (textColorValue != null) {
        customTextColor = Color(textColorValue);
      }
      
      final preset = presetIndex != null && presetIndex < ThemePreset.values.length
          ? ThemePreset.values[presetIndex]
          : ThemePreset.hell;
      
      final shape = shapeIndex != null && shapeIndex < ShapeStyle.values.length
          ? ShapeStyle.values[shapeIndex]
          : ShapeStyle.round;
      
      state = ThemeState(
        preset: preset,
        shape: shape,
        intensity: intensity.clamp(0.0, 1.0),
        customPrimaryColor: customPrimary,
        customSecondaryColor: customSecondary,
        useCustomColors: useCustom,
        backgroundImagePath: backgroundImagePath,
        customTextColor: customTextColor,
        widgetTransparency: widgetTransparency.clamp(0.0, 1.0),
      );
      state.applyToTokens();
    } catch (e) {
      // Bei Fehler Default-Werte behalten
      state.applyToTokens();
    }
  }
  
  /// Speichert das Theme in SharedPreferences
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePresetKey, state.preset.index);
      await prefs.setInt(_shapeStyleKey, state.shape.index);
      await prefs.setDouble(_intensityKey, state.intensity);
      await prefs.setBool(_useCustomColorsKey, state.useCustomColors);
      await prefs.setDouble(_widgetTransparencyKey, state.widgetTransparency);
      
      if (state.customPrimaryColor != null) {
        await prefs.setInt(_customPrimaryKey, state.customPrimaryColor!.value);
      }
      if (state.customSecondaryColor != null) {
        await prefs.setInt(_customSecondaryKey, state.customSecondaryColor!.value);
      }
      if (state.customTextColor != null) {
        await prefs.setInt(_customTextColorKey, state.customTextColor!.value);
      }
      if (state.backgroundImagePath != null) {
        await prefs.setString(_backgroundImagePathKey, state.backgroundImagePath!);
      } else {
        await prefs.remove(_backgroundImagePathKey);
      }
    } catch (e) {
      // Fehler beim Speichern ignorieren
    }
  }
  
  /// Setzt das Theme-Preset
  Future<void> setPreset(ThemePreset preset) async {
    if (state.preset == preset) return;
    
    state = state.copyWith(preset: preset);
    state.applyToTokens();
    await _saveToPrefs();
  }
  
  /// Setzt die Shape-Style
  Future<void> setShape(ShapeStyle shape) async {
    if (state.shape == shape) return;
    
    state = state.copyWith(shape: shape);
    state.applyToTokens();
    await _saveToPrefs();
  }
  
  /// Setzt die Intensität (0.0 - 1.0)
  Future<void> setIntensity(double intensity) async {
    final clampedIntensity = intensity.clamp(0.0, 1.0);
    if (state.intensity == clampedIntensity) return;
    
    state = state.copyWith(intensity: clampedIntensity);
    state.applyToTokens();
    await _saveToPrefs();
  }
  
  /// Setzt benutzerdefinierte Farben
  Future<void> setCustomColors({
    required Color primary,
    Color? secondary,
  }) async {
    state = state.copyWith(
      customPrimaryColor: primary,
      customSecondaryColor: secondary ?? _generateSecondaryColor(primary),
      useCustomColors: true,
    );
    state.applyToTokens();
    await _saveToPrefs();
  }
  
  /// Aktiviert/Deaktiviert benutzerdefinierte Farben
  Future<void> setUseCustomColors(bool use) async {
    if (state.useCustomColors == use) return;
    
    state = state.copyWith(useCustomColors: use);
    state.applyToTokens();
    await _saveToPrefs();
  }
  
  /// Generiert eine passende Sekundärfarbe
  Color _generateSecondaryColor(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    // Verschiebe Hue um 30 Grad für komplementäre Farbe
    return hsl.withHue((hsl.hue + 30) % 360).toColor();
  }
  
  /// Setzt beides gleichzeitig
  Future<void> setTheme(ThemePreset preset, ShapeStyle shape) async {
    if (state.preset == preset && state.shape == shape) return;
    
    state = state.copyWith(preset: preset, shape: shape);
    state.applyToTokens();
    await _saveToPrefs();
  }
  
  /// Wechselt zum nächsten Theme-Preset
  Future<void> nextPreset() async {
    final currentIndex = state.preset.index;
    final nextIndex = (currentIndex + 1) % ThemePreset.values.length;
    await setPreset(ThemePreset.values[nextIndex]);
  }
  
  /// Wechselt die Shape-Style (toggle)
  Future<void> toggleShape() async {
    final newShape = state.shape == ShapeStyle.round
        ? ShapeStyle.square
        : ShapeStyle.round;
    await setShape(newShape);
  }
  
  /// Setzt das Hintergrundbild
  Future<void> setBackgroundImage(String? imagePath) async {
    if (imagePath == null) {
      state = state.copyWith(clearBackgroundImage: true);
    } else {
      state = state.copyWith(backgroundImagePath: imagePath);
    }
    await _saveToPrefs();
  }
  
  /// Entfernt das Hintergrundbild
  Future<void> clearBackgroundImage() async {
    state = state.copyWith(clearBackgroundImage: true);
    await _saveToPrefs();
  }
  
  /// Setzt die benutzerdefinierte Textfarbe
  Future<void> setCustomTextColor(Color? color) async {
    if (color == null) {
      state = state.copyWith(clearTextColor: true);
    } else {
      state = state.copyWith(customTextColor: color);
    }
    await _saveToPrefs();
  }
  
  /// Setzt die Widget-Transparenz (0.0 opak - 1.0 transparent)
  Future<void> setWidgetTransparency(double transparency) async {
    final clampedTransparency = transparency.clamp(0.0, 1.0);
    if (state.widgetTransparency == clampedTransparency) return;
    
    state = state.copyWith(widgetTransparency: clampedTransparency);
    await _saveToPrefs();
  }
  
  /// Setzt alle Einstellungen auf Standard zurück
  Future<void> resetToDefaults() async {
    state = const ThemeState();
    state.applyToTokens();
    await _saveToPrefs();
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Hauptprovider für Theme State
final themeStateProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Provider für aktuelles Theme-Preset
final themePresetProvider = Provider<ThemePreset>((ref) {
  return ref.watch(themeStateProvider).preset;
});

/// Provider für aktuelle Shape-Style
final shapeStyleProvider = Provider<ShapeStyle>((ref) {
  return ref.watch(themeStateProvider).shape;
});

/// Provider für Intensität
final themeIntensityProvider = Provider<double>((ref) {
  return ref.watch(themeStateProvider).intensity;
});

/// Provider für aktuelle Design Tokens
final designTokensProvider = Provider<DesignTokens>((ref) {
  final themeState = ref.watch(themeStateProvider);
  return themeState.tokens;
});

/// Provider um zu prüfen ob Custom Colors aktiv sind
final useCustomColorsProvider = Provider<bool>((ref) {
  return ref.watch(themeStateProvider).useCustomColors;
});

/// Provider für Custom Primary Color
final customPrimaryColorProvider = Provider<Color?>((ref) {
  return ref.watch(themeStateProvider).customPrimaryColor;
});

/// Provider für Hintergrundbild-Pfad
final backgroundImagePathProvider = Provider<String?>((ref) {
  return ref.watch(themeStateProvider).backgroundImagePath;
});

/// Provider um zu prüfen ob ein Hintergrundbild gesetzt ist
final hasBackgroundImageProvider = Provider<bool>((ref) {
  return ref.watch(themeStateProvider).hasBackgroundImage;
});

/// Provider für benutzerdefinierte Textfarbe
final customTextColorProvider = Provider<Color?>((ref) {
  return ref.watch(themeStateProvider).customTextColor;
});

/// Provider für Widget-Transparenz
final widgetTransparencyProvider = Provider<double>((ref) {
  return ref.watch(themeStateProvider).widgetTransparency;
});
