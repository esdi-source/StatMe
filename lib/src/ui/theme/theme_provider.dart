/// Theme Provider für globales Theme-Management
/// 
/// Verwaltet:
/// - Aktuelles Theme-Preset (Fotzig, Glass, Modern, Minimal, Dark, Hell)
/// - Aktuelle Shape-Style (Rund, Eckig)
/// - Persistente Speicherung mit SharedPreferences
/// - Live-Updates an alle Widgets

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_tokens.dart';

// ============================================================================
// STORAGE KEYS
// ============================================================================

const String _themePresetKey = 'theme_preset';
const String _shapeStyleKey = 'shape_style';

// ============================================================================
// THEME STATE
// ============================================================================

/// Kombinierter Theme State
class ThemeState {
  final ThemePreset preset;
  final ShapeStyle shape;
  
  const ThemeState({
    this.preset = ThemePreset.hell,
    this.shape = ShapeStyle.round,
  });
  
  ThemeState copyWith({
    ThemePreset? preset,
    ShapeStyle? shape,
  }) {
    return ThemeState(
      preset: preset ?? this.preset,
      shape: shape ?? this.shape,
    );
  }
  
  /// Aktualisiert die globalen Design Tokens
  void applyToTokens() {
    DesignTokens.setPreset(preset);
    DesignTokens.setShape(shape);
  }
  
  /// Gibt die aktuellen Design Tokens zurück
  DesignTokens get tokens => DesignTokens.forPreset(preset, shape);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          runtimeType == other.runtimeType &&
          preset == other.preset &&
          shape == other.shape;
  
  @override
  int get hashCode => preset.hashCode ^ shape.hashCode;
}

// ============================================================================
// THEME NOTIFIER
// ============================================================================

/// StateNotifier für Theme-Management
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadFromPrefs();
  }
  
  /// Lädt das Theme aus SharedPreferences
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final presetIndex = prefs.getInt(_themePresetKey);
      final shapeIndex = prefs.getInt(_shapeStyleKey);
      
      final preset = presetIndex != null && presetIndex < ThemePreset.values.length
          ? ThemePreset.values[presetIndex]
          : ThemePreset.hell;
      
      final shape = shapeIndex != null && shapeIndex < ShapeStyle.values.length
          ? ShapeStyle.values[shapeIndex]
          : ShapeStyle.round;
      
      state = ThemeState(preset: preset, shape: shape);
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
  
  /// Setzt beides gleichzeitig
  Future<void> setTheme(ThemePreset preset, ShapeStyle shape) async {
    if (state.preset == preset && state.shape == shape) return;
    
    state = ThemeState(preset: preset, shape: shape);
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

/// Provider für aktuelle Design Tokens
final designTokensProvider = Provider<DesignTokens>((ref) {
  final themeState = ref.watch(themeStateProvider);
  return themeState.tokens;
});

/// Provider um zu prüfen ob Dark Theme aktiv ist
final isDarkThemeProvider = Provider<bool>((ref) {
  final preset = ref.watch(themePresetProvider);
  return preset == ThemePreset.dark;
});

/// Provider um zu prüfen ob Glass Theme aktiv ist
final isGlassThemeProvider = Provider<bool>((ref) {
  final preset = ref.watch(themePresetProvider);
  return preset == ThemePreset.glass;
});
