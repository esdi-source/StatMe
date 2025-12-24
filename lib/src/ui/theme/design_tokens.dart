/// Design Token System für globales Theming
/// 
/// Zentrale Definition aller Style-Variablen:
/// - Farben (Primary, Secondary, Surface, etc.)
/// - Intensitätsstufen für Farben
/// - Radien (BorderRadius)
/// - Schatten (BoxShadow)
/// - Typografie-Scales
/// - Abstände (Spacing)
/// 
/// Widgets referenzieren diese Tokens statt fester Werte.
library;

import 'package:flutter/material.dart';

// ============================================================================
// THEME PRESET ENUM (ohne Glass)
// ============================================================================

/// Verfügbare Theme-Presets
enum ThemePreset {
  fotzig('Fotzig', 'Lebendige Pastellfarben, verspielt'),
  modern('Modern', 'Neutral, klare Kontraste, technisch'),
  minimal('Minimal', 'Schwarz/Weiß/Grau, Fokus auf Inhalt'),
  hell('Hell', 'Heller Hintergrund, hohe Lesbarkeit');

  final String label;
  final String description;
  const ThemePreset(this.label, this.description);
}

// ============================================================================
// SHAPE STYLE ENUM
// ============================================================================

/// Shape-System: Rund oder Eckig
enum ShapeStyle {
  round('Rund', 'Abgerundete Ecken, weicher Look'),
  square('Eckig', 'Scharfe Ecken, moderner Look');

  final String label;
  final String description;
  const ShapeStyle(this.label, this.description);
}

// ============================================================================
// DESIGN TOKENS CLASS
// ============================================================================

/// Zentrale Design Tokens - alle Widgets referenzieren diese Werte
class DesignTokens {
  // Singleton instance basierend auf aktuellem Theme
  static DesignTokens? _instance;
  static ThemePreset _currentPreset = ThemePreset.hell;
  static ShapeStyle _currentShape = ShapeStyle.round;
  static double _currentIntensity = 0.7;
  static Color? _customPrimary;
  static Color? _customSecondary;
  
  /// Aktuelles Theme Preset
  static ThemePreset get currentPreset => _currentPreset;
  
  /// Aktuelle Shape-Style
  static ShapeStyle get currentShape => _currentShape;
  
  /// Aktuelle Intensität
  static double get currentIntensity => _currentIntensity;
  
  /// Setzt das Theme-Preset (invalidiert Cache)
  static void setPreset(ThemePreset preset) {
    if (_currentPreset != preset) {
      _currentPreset = preset;
      _instance = null;
    }
  }
  
  /// Setzt die Shape-Style (invalidiert Cache)
  static void setShape(ShapeStyle shape) {
    if (_currentShape != shape) {
      _currentShape = shape;
      _instance = null;
    }
  }
  
  /// Setzt die Intensität (invalidiert Cache)
  static void setIntensity(double intensity) {
    if (_currentIntensity != intensity) {
      _currentIntensity = intensity.clamp(0.0, 1.0);
      _instance = null;
    }
  }
  
  /// Setzt benutzerdefinierte Farben
  static void setCustomColors(Color? primary, Color? secondary) {
    _customPrimary = primary;
    _customSecondary = secondary;
    _instance = null;
  }
  
  /// Entfernt benutzerdefinierte Farben
  static void clearCustomColors() {
    _customPrimary = null;
    _customSecondary = null;
    _instance = null;
  }
  
  /// Gibt die aktuellen Tokens zurück
  static DesignTokens get current {
    _instance ??= DesignTokens._create(
      _currentPreset, 
      _currentShape,
      _currentIntensity,
      _customPrimary,
      _customSecondary,
    );
    return _instance!;
  }
  
  /// Erstellt Tokens für ein bestimmtes Preset und Shape
  static DesignTokens forPreset(
    ThemePreset preset, 
    ShapeStyle shape, {
    double intensity = 0.7,
    Color? customPrimary,
    Color? customSecondary,
  }) {
    return DesignTokens._create(preset, shape, intensity, customPrimary, customSecondary);
  }
  
  // ---------------------------------------------------------------------------
  // FARBEN
  // ---------------------------------------------------------------------------
  
  /// Primärfarbe (Hauptakzent)
  final Color primary;
  
  /// Sekundärfarbe
  final Color secondary;
  
  /// Hintergrundfarbe der App
  final Color background;
  
  /// Oberflächenfarbe (Cards, etc.)
  final Color surface;
  
  /// Erhöhte Oberfläche (Dialoge, Modals)
  final Color surfaceElevated;
  
  /// Primäre Textfarbe
  final Color textPrimary;
  
  /// Sekundäre Textfarbe (gedämpft)
  final Color textSecondary;
  
  /// Deaktivierter Text
  final Color textDisabled;
  
  /// Erfolgsfarbe
  final Color success;
  
  /// Warnfarbe
  final Color warning;
  
  /// Fehlerfarbe
  final Color error;
  
  /// Infofarbe
  final Color info;
  
  /// Divider/Border Farbe
  final Color divider;
  
  /// Card Border Farbe
  final Color cardBorder;
  
  /// Overlay Farbe
  final Color overlay;
  
  // ---------------------------------------------------------------------------
  // RADIEN
  // ---------------------------------------------------------------------------
  
  /// Kleiner Radius (Buttons, kleine Elemente)
  final double radiusSmall;
  
  /// Mittlerer Radius (Cards, Inputs)
  final double radiusMedium;
  
  /// Großer Radius (Modals, große Cards)
  final double radiusLarge;
  
  /// Extra großer Radius (Sheets, besondere Elemente)
  final double radiusXLarge;
  
  /// Vollständig rund (Pills, Chips)
  final double radiusFull;
  
  // ---------------------------------------------------------------------------
  // SCHATTEN
  // ---------------------------------------------------------------------------
  
  /// Kein Schatten
  final List<BoxShadow> shadowNone;
  
  /// Subtiler Schatten (leichte Erhebung)
  final List<BoxShadow> shadowSubtle;
  
  /// Kleiner Schatten (Cards)
  final List<BoxShadow> shadowSmall;
  
  /// Mittlerer Schatten (erhöhte Elemente)
  final List<BoxShadow> shadowMedium;
  
  /// Großer Schatten (Modals, Dropdowns)
  final List<BoxShadow> shadowLarge;
  
  // ---------------------------------------------------------------------------
  // ABSTÄNDE (SPACING)
  // ---------------------------------------------------------------------------
  
  /// Extra kleiner Abstand (4px)
  final double spacingXS;
  
  /// Kleiner Abstand (8px)
  final double spacingS;
  
  /// Mittlerer Abstand (16px)
  final double spacingM;
  
  /// Großer Abstand (24px)
  final double spacingL;
  
  /// Extra großer Abstand (32px)
  final double spacingXL;
  
  /// XXL Abstand (48px)
  final double spacingXXL;
  
  // ---------------------------------------------------------------------------
  // TYPOGRAFIE
  // ---------------------------------------------------------------------------
  
  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;
  
  // ---------------------------------------------------------------------------
  // ANIMATION
  // ---------------------------------------------------------------------------
  
  final Duration animationDuration;
  final Duration animationFast;
  final Duration animationSlow;
  final Curve animationCurve;
  
  // ---------------------------------------------------------------------------
  // PRIVATE CONSTRUCTOR
  // ---------------------------------------------------------------------------
  
  const DesignTokens._({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.divider,
    required this.cardBorder,
    required this.overlay,
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
    required this.radiusXLarge,
    required this.radiusFull,
    required this.shadowNone,
    required this.shadowSubtle,
    required this.shadowSmall,
    required this.shadowMedium,
    required this.shadowLarge,
    required this.spacingXS,
    required this.spacingS,
    required this.spacingM,
    required this.spacingL,
    required this.spacingXL,
    required this.spacingXXL,
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
    required this.animationDuration,
    required this.animationFast,
    required this.animationSlow,
    required this.animationCurve,
  });
  
  // ---------------------------------------------------------------------------
  // FACTORY - THEME CREATION
  // ---------------------------------------------------------------------------
  
  factory DesignTokens._create(
    ThemePreset preset, 
    ShapeStyle shape,
    double intensity,
    Color? customPrimary,
    Color? customSecondary,
  ) {
    final radii = _getRadii(shape);
    
    switch (preset) {
      case ThemePreset.fotzig:
        return _createFotzig(radii, intensity, customPrimary, customSecondary);
      case ThemePreset.modern:
        return _createModern(radii, intensity, customPrimary, customSecondary);
      case ThemePreset.minimal:
        return _createMinimal(radii, intensity, customPrimary, customSecondary);
      case ThemePreset.hell:
        return _createHell(radii, intensity, customPrimary, customSecondary);
    }
  }
  
  // ---------------------------------------------------------------------------
  // RADII BASED ON SHAPE
  // ---------------------------------------------------------------------------
  
  static _Radii _getRadii(ShapeStyle shape) {
    switch (shape) {
      case ShapeStyle.round:
        return const _Radii(
          small: 8,
          medium: 16,
          large: 24,
          xLarge: 32,
          full: 999,
        );
      case ShapeStyle.square:
        return const _Radii(
          small: 2,
          medium: 4,
          large: 8,
          xLarge: 12,
          full: 999,
        );
    }
  }
  
  // ---------------------------------------------------------------------------
  // INTENSITY HELPER
  // ---------------------------------------------------------------------------
  
  /// Passt eine Farbe basierend auf Intensität an
  static Color _applyIntensity(Color baseColor, double intensity) {
    final hsl = HSLColor.fromColor(baseColor);
    // Intensität beeinflusst Sättigung: 0.0 = entsättigt, 1.0 = voll gesättigt
    final newSaturation = hsl.saturation * (0.3 + (intensity * 0.7));
    // Bei höherer Intensität auch leicht dunklere Farben für mehr Kontrast
    final newLightness = hsl.lightness * (0.95 + (intensity * 0.1));
    return hsl
        .withSaturation(newSaturation.clamp(0.0, 1.0))
        .withLightness(newLightness.clamp(0.0, 1.0))
        .toColor();
  }
  
  /// Intensiviert eine Farbe (macht sie kräftiger)
  static Color _intensify(Color color, double intensity) {
    final hsl = HSLColor.fromColor(color);
    // Mehr Sättigung bei höherer Intensität
    final newSaturation = (hsl.saturation + (intensity * 0.3)).clamp(0.0, 1.0);
    return hsl.withSaturation(newSaturation).toColor();
  }
  
  // ---------------------------------------------------------------------------
  // BASE TEXT STYLES
  // ---------------------------------------------------------------------------
  
  static TextStyle _baseTextStyle(Color color) => TextStyle(
    fontFamily: '.SF Pro Text',
    color: color,
    decoration: TextDecoration.none,
  );
  
  static _Typography _createTypography(Color primary, Color secondary) {
    return _Typography(
      displayLarge: _baseTextStyle(primary).copyWith(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 0.25),
      displayMedium: _baseTextStyle(primary).copyWith(fontSize: 28, fontWeight: FontWeight.w600),
      displaySmall: _baseTextStyle(primary).copyWith(fontSize: 24, fontWeight: FontWeight.w600),
      headlineLarge: _baseTextStyle(primary).copyWith(fontSize: 22, fontWeight: FontWeight.w600),
      headlineMedium: _baseTextStyle(primary).copyWith(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.15),
      headlineSmall: _baseTextStyle(primary).copyWith(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.15),
      titleLarge: _baseTextStyle(primary).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      titleMedium: _baseTextStyle(primary).copyWith(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
      titleSmall: _baseTextStyle(primary).copyWith(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      bodyLarge: _baseTextStyle(primary).copyWith(fontSize: 17, fontWeight: FontWeight.w400),
      bodyMedium: _baseTextStyle(primary).copyWith(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0.25),
      bodySmall: _baseTextStyle(secondary).copyWith(fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 0.4),
      labelLarge: _baseTextStyle(primary).copyWith(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      labelMedium: _baseTextStyle(primary).copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      labelSmall: _baseTextStyle(secondary).copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    );
  }
  
  // ---------------------------------------------------------------------------
  // THEME: FOTZIG (Vibrant, Playful) - Intensivere Farben
  // ---------------------------------------------------------------------------
  
  static DesignTokens _createFotzig(_Radii radii, double intensity, Color? customPrimary, Color? customSecondary) {
    // Basis: Lebhafte Pink/Lila-Töne
    final basePrimary = customPrimary ?? const Color(0xFFE91E8C); // Vivid Pink
    final baseSecondary = customSecondary ?? const Color(0xFF9C27B0); // Deep Purple
    
    final primary = _intensify(basePrimary, intensity);
    final secondary = _intensify(baseSecondary, intensity);
    
    const background = Color(0xFFFFF0F5); // Lavender Blush
    const surface = Color(0xFFFFFFFF);
    const surfaceElevated = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF2D1B33); // Dark Purple
    const textSecondary = Color(0xFF6B5277);
    const textDisabled = Color(0xFFB5A3BC);
    
    final typography = _createTypography(textPrimary, textSecondary);
    
    return DesignTokens._(
      primary: primary,
      secondary: secondary,
      background: background,
      surface: surface,
      surfaceElevated: surfaceElevated,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textDisabled: textDisabled,
      success: _intensify(const Color(0xFF4CAF50), intensity),
      warning: _intensify(const Color(0xFFFF9800), intensity),
      error: _intensify(const Color(0xFFF44336), intensity),
      info: _intensify(const Color(0xFF2196F3), intensity),
      divider: const Color(0xFFF0E0E8),
      cardBorder: const Color(0xFFE8D0E0),
      overlay: primary.withOpacity(0.1),
      radiusSmall: radii.small,
      radiusMedium: radii.medium,
      radiusLarge: radii.large,
      radiusXLarge: radii.xLarge,
      radiusFull: radii.full,
      shadowNone: const [],
      shadowSubtle: [
        BoxShadow(
          color: primary.withOpacity(0.08 * intensity),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      shadowSmall: [
        BoxShadow(
          color: primary.withOpacity(0.12 * intensity),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      shadowMedium: [
        BoxShadow(
          color: primary.withOpacity(0.15 * intensity),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
      shadowLarge: [
        BoxShadow(
          color: primary.withOpacity(0.2 * intensity),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
      spacingXS: 4,
      spacingS: 8,
      spacingM: 16,
      spacingL: 24,
      spacingXL: 32,
      spacingXXL: 48,
      displayLarge: typography.displayLarge,
      displayMedium: typography.displayMedium,
      displaySmall: typography.displaySmall,
      headlineLarge: typography.headlineLarge,
      headlineMedium: typography.headlineMedium,
      headlineSmall: typography.headlineSmall,
      titleLarge: typography.titleLarge,
      titleMedium: typography.titleMedium,
      titleSmall: typography.titleSmall,
      bodyLarge: typography.bodyLarge,
      bodyMedium: typography.bodyMedium,
      bodySmall: typography.bodySmall,
      labelLarge: typography.labelLarge,
      labelMedium: typography.labelMedium,
      labelSmall: typography.labelSmall,
      animationDuration: const Duration(milliseconds: 300),
      animationFast: const Duration(milliseconds: 150),
      animationSlow: const Duration(milliseconds: 500),
      animationCurve: Curves.easeInOutCubic,
    );
  }
  
  // ---------------------------------------------------------------------------
  // THEME: MODERN (Clean, Technical) - Intensivere Farben
  // ---------------------------------------------------------------------------
  
  static DesignTokens _createModern(_Radii radii, double intensity, Color? customPrimary, Color? customSecondary) {
    final basePrimary = customPrimary ?? const Color(0xFF2563EB); // Vivid Blue
    final baseSecondary = customSecondary ?? const Color(0xFF7C3AED); // Vivid Purple
    
    final primary = _intensify(basePrimary, intensity);
    final secondary = _intensify(baseSecondary, intensity);
    
    const background = Color(0xFFF8FAFC);
    const surface = Color(0xFFFFFFFF);
    const surfaceElevated = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const textDisabled = Color(0xFF94A3B8);
    
    final typography = _createTypography(textPrimary, textSecondary);
    
    return DesignTokens._(
      primary: primary,
      secondary: secondary,
      background: background,
      surface: surface,
      surfaceElevated: surfaceElevated,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textDisabled: textDisabled,
      success: _intensify(const Color(0xFF16A34A), intensity),
      warning: _intensify(const Color(0xFFEAB308), intensity),
      error: _intensify(const Color(0xFFDC2626), intensity),
      info: _intensify(const Color(0xFF0EA5E9), intensity),
      divider: const Color(0xFFE2E8F0),
      cardBorder: const Color(0xFFE2E8F0),
      overlay: const Color(0x10000000),
      radiusSmall: radii.small,
      radiusMedium: radii.medium,
      radiusLarge: radii.large,
      radiusXLarge: radii.xLarge,
      radiusFull: radii.full,
      shadowNone: const [],
      shadowSubtle: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03 * intensity),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
      shadowSmall: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05 * intensity),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      shadowMedium: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08 * intensity),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
      shadowLarge: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1 * intensity),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
      spacingXS: 4,
      spacingS: 8,
      spacingM: 16,
      spacingL: 24,
      spacingXL: 32,
      spacingXXL: 48,
      displayLarge: typography.displayLarge,
      displayMedium: typography.displayMedium,
      displaySmall: typography.displaySmall,
      headlineLarge: typography.headlineLarge,
      headlineMedium: typography.headlineMedium,
      headlineSmall: typography.headlineSmall,
      titleLarge: typography.titleLarge,
      titleMedium: typography.titleMedium,
      titleSmall: typography.titleSmall,
      bodyLarge: typography.bodyLarge,
      bodyMedium: typography.bodyMedium,
      bodySmall: typography.bodySmall,
      labelLarge: typography.labelLarge,
      labelMedium: typography.labelMedium,
      labelSmall: typography.labelSmall,
      animationDuration: const Duration(milliseconds: 250),
      animationFast: const Duration(milliseconds: 150),
      animationSlow: const Duration(milliseconds: 400),
      animationCurve: Curves.easeOutCubic,
    );
  }
  
  // ---------------------------------------------------------------------------
  // THEME: MINIMAL (Black/White/Grey)
  // ---------------------------------------------------------------------------
  
  static DesignTokens _createMinimal(_Radii radii, double intensity, Color? customPrimary, Color? customSecondary) {
    final primary = customPrimary ?? const Color(0xFF000000);
    final secondary = customSecondary ?? const Color(0xFF525252);
    
    const background = Color(0xFFFFFFFF);
    const surface = Color(0xFFFFFFFF);
    const surfaceElevated = Color(0xFFFAFAFA);
    const textPrimary = Color(0xFF000000);
    const textSecondary = Color(0xFF737373);
    const textDisabled = Color(0xFFD4D4D4);
    
    final typography = _createTypography(textPrimary, textSecondary);
    
    return DesignTokens._(
      primary: primary,
      secondary: secondary,
      background: background,
      surface: surface,
      surfaceElevated: surfaceElevated,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textDisabled: textDisabled,
      success: const Color(0xFF22C55E),
      warning: const Color(0xFFF59E0B),
      error: const Color(0xFFEF4444),
      info: const Color(0xFF3B82F6),
      divider: const Color(0xFFE5E5E5),
      cardBorder: const Color(0xFFE5E5E5),
      overlay: const Color(0x08000000),
      radiusSmall: radii.small,
      radiusMedium: radii.medium,
      radiusLarge: radii.large,
      radiusXLarge: radii.xLarge,
      radiusFull: radii.full,
      shadowNone: const [],
      shadowSubtle: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
      shadowSmall: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      shadowMedium: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      shadowLarge: [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
      spacingXS: 4,
      spacingS: 8,
      spacingM: 16,
      spacingL: 24,
      spacingXL: 32,
      spacingXXL: 48,
      displayLarge: typography.displayLarge,
      displayMedium: typography.displayMedium,
      displaySmall: typography.displaySmall,
      headlineLarge: typography.headlineLarge,
      headlineMedium: typography.headlineMedium,
      headlineSmall: typography.headlineSmall,
      titleLarge: typography.titleLarge,
      titleMedium: typography.titleMedium,
      titleSmall: typography.titleSmall,
      bodyLarge: typography.bodyLarge,
      bodyMedium: typography.bodyMedium,
      bodySmall: typography.bodySmall,
      labelLarge: typography.labelLarge,
      labelMedium: typography.labelMedium,
      labelSmall: typography.labelSmall,
      animationDuration: const Duration(milliseconds: 200),
      animationFast: const Duration(milliseconds: 100),
      animationSlow: const Duration(milliseconds: 350),
      animationCurve: Curves.easeInOut,
    );
  }
  
  // ---------------------------------------------------------------------------
  // THEME: HELL (Light, high readability) - Intensivere Farben
  // ---------------------------------------------------------------------------
  
  static DesignTokens _createHell(_Radii radii, double intensity, Color? customPrimary, Color? customSecondary) {
    final basePrimary = customPrimary ?? const Color(0xFF3B82F6); // Vivid Blue
    final baseSecondary = customSecondary ?? const Color(0xFF8B5CF6); // Vivid Purple
    
    final primary = _intensify(basePrimary, intensity);
    final secondary = _intensify(baseSecondary, intensity);
    
    const background = Color(0xFFFAFAFA);
    const surface = Color(0xFFFFFFFF);
    const surfaceElevated = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF171717);
    const textSecondary = Color(0xFF525252);
    const textDisabled = Color(0xFFA3A3A3);
    
    final typography = _createTypography(textPrimary, textSecondary);
    
    return DesignTokens._(
      primary: primary,
      secondary: secondary,
      background: background,
      surface: surface,
      surfaceElevated: surfaceElevated,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textDisabled: textDisabled,
      success: _intensify(const Color(0xFF22C55E), intensity),
      warning: _intensify(const Color(0xFFF59E0B), intensity),
      error: _intensify(const Color(0xFFEF4444), intensity),
      info: _intensify(const Color(0xFF0EA5E9), intensity),
      divider: const Color(0xFFE5E5E5),
      cardBorder: const Color(0xFFE5E5E5),
      overlay: const Color(0x08000000),
      radiusSmall: radii.small,
      radiusMedium: radii.medium,
      radiusLarge: radii.large,
      radiusXLarge: radii.xLarge,
      radiusFull: radii.full,
      shadowNone: const [],
      shadowSubtle: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
      shadowSmall: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
      shadowMedium: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
      shadowLarge: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
      spacingXS: 4,
      spacingS: 8,
      spacingM: 16,
      spacingL: 24,
      spacingXL: 32,
      spacingXXL: 48,
      displayLarge: typography.displayLarge,
      displayMedium: typography.displayMedium,
      displaySmall: typography.displaySmall,
      headlineLarge: typography.headlineLarge,
      headlineMedium: typography.headlineMedium,
      headlineSmall: typography.headlineSmall,
      titleLarge: typography.titleLarge,
      titleMedium: typography.titleMedium,
      titleSmall: typography.titleSmall,
      bodyLarge: typography.bodyLarge,
      bodyMedium: typography.bodyMedium,
      bodySmall: typography.bodySmall,
      labelLarge: typography.labelLarge,
      labelMedium: typography.labelMedium,
      labelSmall: typography.labelSmall,
      animationDuration: const Duration(milliseconds: 250),
      animationFast: const Duration(milliseconds: 150),
      animationSlow: const Duration(milliseconds: 400),
      animationCurve: Curves.easeOutCubic,
    );
  }
  
  // ---------------------------------------------------------------------------
  // CONVENIENCE METHODS
  // ---------------------------------------------------------------------------
  
  /// Erstellt eine Card-Decoration mit den aktuellen Tokens
  BoxDecoration cardDecoration({List<BoxShadow>? shadow}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(color: cardBorder, width: 1),
      boxShadow: shadow ?? shadowSmall,
    );
  }
  
  /// Erstellt eine Button-Decoration
  BoxDecoration buttonDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? primary,
      borderRadius: BorderRadius.circular(radiusSmall),
    );
  }
  
  /// Erstellt eine Input-Decoration
  InputDecoration inputDecoration({String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    );
  }
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

class _Radii {
  final double small;
  final double medium;
  final double large;
  final double xLarge;
  final double full;
  
  const _Radii({
    required this.small,
    required this.medium,
    required this.large,
    required this.xLarge,
    required this.full,
  });
}

class _Typography {
  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;
  
  const _Typography({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
  });
}

// ============================================================================
// THEMED CARD WIDGET
// ============================================================================

/// Card Widget das automatisch die aktuellen Design Tokens verwendet
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;
  
  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.shadow,
  });
  
  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.current;
    
    Widget card = Container(
      padding: padding ?? EdgeInsets.all(tokens.spacingM),
      decoration: tokens.cardDecoration(shadow: shadow),
      child: child,
    );
    
    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    
    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }
    
    return card;
  }
}
