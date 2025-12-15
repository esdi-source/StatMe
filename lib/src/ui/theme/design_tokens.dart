/// Design Token System für globales Theming
/// 
/// Zentrale Definition aller Style-Variablen:
/// - Farben (Primary, Secondary, Surface, etc.)
/// - Radien (BorderRadius)
/// - Schatten (BoxShadow)
/// - Typografie-Scales
/// - Abstände (Spacing)
/// 
/// Widgets referenzieren diese Tokens statt fester Werte.

import 'package:flutter/material.dart';
import 'dart:ui';

// ============================================================================
// THEME PRESET ENUM
// ============================================================================

/// Verfügbare Theme-Presets
enum ThemePreset {
  fotzig('Fotzig', 'Pastellfarben, weich, verspielt'),
  glass('Glass', 'Transparenz, Blur, Glassmorphism'),
  modern('Modern', 'Neutral, klare Kontraste, technisch'),
  minimal('Minimal', 'Schwarz/Weiß/Grau, Fokus auf Inhalt'),
  dark('Dark', 'Dunkle Hintergründe, augenschonend'),
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
  
  /// Aktuelles Theme Preset
  static ThemePreset get currentPreset => _currentPreset;
  
  /// Aktuelle Shape-Style
  static ShapeStyle get currentShape => _currentShape;
  
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
  
  /// Gibt die aktuellen Tokens zurück
  static DesignTokens get current {
    _instance ??= DesignTokens._create(_currentPreset, _currentShape);
    return _instance!;
  }
  
  /// Erstellt Tokens für ein bestimmtes Preset und Shape
  static DesignTokens forPreset(ThemePreset preset, ShapeStyle shape) {
    return DesignTokens._create(preset, shape);
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
  
  /// Overlay Farbe (für Glassmorphism)
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
  // BLUR / GLASSMORPHISM
  // ---------------------------------------------------------------------------
  
  /// Blur-Intensität für Glassmorphism
  final double blurAmount;
  
  /// Ob Glassmorphism aktiv ist
  final bool useGlass;
  
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
  
  /// Display Text (große Überschriften)
  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;
  
  /// Headline Text
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;
  
  /// Title Text
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  
  /// Body Text
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  
  /// Label Text
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;
  
  // ---------------------------------------------------------------------------
  // ANIMATION
  // ---------------------------------------------------------------------------
  
  /// Standard Animation Duration
  final Duration animationDuration;
  
  /// Schnelle Animation
  final Duration animationFast;
  
  /// Langsame Animation
  final Duration animationSlow;
  
  /// Standard Curve
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
    required this.blurAmount,
    required this.useGlass,
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
  
  factory DesignTokens._create(ThemePreset preset, ShapeStyle shape) {
    // Radien basierend auf Shape
    final radii = _getRadii(shape);
    
    // Farben und Schatten basierend auf Preset
    switch (preset) {
      case ThemePreset.fotzig:
        return _createFotzig(radii);
      case ThemePreset.glass:
        return _createGlass(radii);
      case ThemePreset.modern:
        return _createModern(radii);
      case ThemePreset.minimal:
        return _createMinimal(radii);
      case ThemePreset.dark:
        return _createDark(radii);
      case ThemePreset.hell:
        return _createHell(radii);
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
  // BASE TEXT STYLES (Apple HIG inspired)
  // ---------------------------------------------------------------------------
  
  static TextStyle _baseTextStyle(Color color) => TextStyle(
    fontFamily: '.SF Pro Text',
    color: color,
    decoration: TextDecoration.none,
  );
  
  static _Typography _createTypography(Color primary, Color secondary) {
    return _Typography(
      displayLarge: _baseTextStyle(primary).copyWith(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 0.25),
      displayMedium: _baseTextStyle(primary).copyWith(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 0),
      displaySmall: _baseTextStyle(primary).copyWith(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0),
      headlineLarge: _baseTextStyle(primary).copyWith(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0),
      headlineMedium: _baseTextStyle(primary).copyWith(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.15),
      headlineSmall: _baseTextStyle(primary).copyWith(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.15),
      titleLarge: _baseTextStyle(primary).copyWith(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0),
      titleMedium: _baseTextStyle(primary).copyWith(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
      titleSmall: _baseTextStyle(primary).copyWith(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      bodyLarge: _baseTextStyle(primary).copyWith(fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: 0),
      bodyMedium: _baseTextStyle(primary).copyWith(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0.25),
      bodySmall: _baseTextStyle(secondary).copyWith(fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 0.4),
      labelLarge: _baseTextStyle(primary).copyWith(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      labelMedium: _baseTextStyle(primary).copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      labelSmall: _baseTextStyle(secondary).copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    );
  }
  
  // ---------------------------------------------------------------------------
  // THEME: FOTZIG (Girls/Soft)
  // ---------------------------------------------------------------------------
  
  static DesignTokens _createFotzig(_Radii radii) {
    const primary = Color(0xFFE8A4C9); // Soft Pink
    const secondary = Color(0xFFB8A4E8); // Soft Lavender
    const background = Color(0xFFFFF5F8); // Very Light Pink
    const surface = Color(0xFFFFFFFF);
    const surfaceElevated = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF4A3F55); // Soft Dark Purple
    const textSecondary = Color(0xFF8A7F95);
    const textDisabled = Color(0xFFBDB5C5);
    
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
      success: const Color(0xFF9DD6B0),
      warning: const Color(0xFFF5D89A),
      error: const Color(0xFFF5A5A5),
      info: const Color(0xFFA5C9F5),
      divider: const Color(0xFFF0E5EB),
      cardBorder: const Color(0xFFF5E0EA),
      overlay: const Color(0x20E8A4C9),
      radiusSmall: radii.small,
      radiusMedium: radii.medium,
      radiusLarge: radii.large,
      radiusXLarge: radii.xLarge,
      radiusFull: radii.full,
      shadowNone: const [],
      shadowSubtle: [
        BoxShadow(
          color: const Color(0xFFE8A4C9).withOpacity(0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      shadowSmall: [
        BoxShadow(
          color: const Color(0xFFE8A4C9).withOpacity(0.12),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      shadowMedium: [
        BoxShadow(
          color: const Color(0xFFE8A4C9).withOpacity(0.15),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
      shadowLarge: [
        BoxShadow(
          color: const Color(0xFFE8A4C9).withOpacity(0.2),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
      blurAmount: 0,
      useGlass: false,
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
  // THEME: GLASS (Glassmorphism)
  // ---------------------------------------------------------------------------
  
  static DesignTokens _createGlass(_Radii radii) {
    const primary = Color(0xFF6E8EFA); // Bright Blue
    const secondary = Color(0xFFA78BFA); // Light Purple
    const background = Color(0xFFF0F4FF); // Very Light Blue
    const surface = Color(0xBBFFFFFF); // Semi-transparent White
    const surfaceElevated = Color(0xDDFFFFFF);
    const textPrimary = Color(0xFF1A1A2E);
    const textSecondary = Color(0xFF4A4A6A);
    const textDisabled = Color(0xFF9A9ABB);
    
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
      success: const Color(0xFF4ADE80),
      warning: const Color(0xFFFBBF24),
      error: const Color(0xFFF87171),
      info: const Color(0xFF60A5FA),
      divider: const Color(0x20000000),
      cardBorder: const Color(0x40FFFFFF),
      overlay: const Color(0x40FFFFFF),
      radiusSmall: radii.small,
      radiusMedium: radii.medium,
      radiusLarge: radii.large,
      radiusXLarge: radii.xLarge,
      radiusFull: radii.full,
      shadowNone: const [],
      shadowSubtle: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      shadowSmall: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF6E8EFA).withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      shadowMedium: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFF6E8EFA).withOpacity(0.15),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ],
      shadowLarge: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: const Color(0xFF6E8EFA).withOpacity(0.2),
          blurRadius: 48,
          offset: const Offset(0, 24),
        ),
      ],
      blurAmount: 20,
      useGlass: true,
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
      animationDuration: const Duration(milliseconds: 350),
      animationFast: const Duration(milliseconds: 200),
      animationSlow: const Duration(milliseconds: 600),
      animationCurve: Curves.easeOutQuint,
    );
  }
  
  // ---------------------------------------------------------------------------
  // THEME: MODERN (Neutral, Technical)
  // ---------------------------------------------------------------------------
  
  static DesignTokens _createModern(_Radii radii) {
    const primary = Color(0xFF3B82F6); // Blue
    const secondary = Color(0xFF6366F1); // Indigo
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
      success: const Color(0xFF22C55E),
      warning: const Color(0xFFF59E0B),
      error: const Color(0xFFEF4444),
      info: const Color(0xFF0EA5E9),
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
          color: Colors.black.withOpacity(0.03),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
      shadowSmall: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      shadowMedium: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
      shadowLarge: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ],
      blurAmount: 0,
      useGlass: false,
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
  // THEME: MINIMAL (Black/White/Gray)
  // ---------------------------------------------------------------------------
  
  static DesignTokens _createMinimal(_Radii radii) {
    const primary = Color(0xFF171717); // Near Black
    const secondary = Color(0xFF525252);
    const background = Color(0xFFFFFFFF);
    const surface = Color(0xFFFFFFFF);
    const surfaceElevated = Color(0xFFFAFAFA);
    const textPrimary = Color(0xFF171717);
    const textSecondary = Color(0xFF737373);
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
      success: const Color(0xFF171717),
      warning: const Color(0xFF525252),
      error: const Color(0xFF171717),
      info: const Color(0xFF525252),
      divider: const Color(0xFFE5E5E5),
      cardBorder: const Color(0xFFE5E5E5),
      overlay: const Color(0x08000000),
      radiusSmall: radii.small,
      radiusMedium: radii.medium,
      radiusLarge: radii.large,
      radiusXLarge: radii.xLarge,
      radiusFull: radii.full,
      shadowNone: const [],
      shadowSubtle: const [],
      shadowSmall: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
      shadowMedium: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
      shadowLarge: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
      blurAmount: 0,
      useGlass: false,
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
      animationCurve: Curves.easeOut,
    );
  }
  
  // ---------------------------------------------------------------------------
  // THEME: DARK (Dark Mode)
  // ---------------------------------------------------------------------------
  
  static DesignTokens _createDark(_Radii radii) {
    const primary = Color(0xFF60A5FA); // Light Blue
    const secondary = Color(0xFFA78BFA); // Light Purple
    const background = Color(0xFF0F0F0F);
    const surface = Color(0xFF1A1A1A);
    const surfaceElevated = Color(0xFF262626);
    const textPrimary = Color(0xFFF5F5F5);
    const textSecondary = Color(0xFFA3A3A3);
    const textDisabled = Color(0xFF525252);
    
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
      success: const Color(0xFF4ADE80),
      warning: const Color(0xFFFBBF24),
      error: const Color(0xFFF87171),
      info: const Color(0xFF38BDF8),
      divider: const Color(0xFF262626),
      cardBorder: const Color(0xFF333333),
      overlay: const Color(0x30FFFFFF),
      radiusSmall: radii.small,
      radiusMedium: radii.medium,
      radiusLarge: radii.large,
      radiusXLarge: radii.xLarge,
      radiusFull: radii.full,
      shadowNone: const [],
      shadowSubtle: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      shadowSmall: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      shadowMedium: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
      shadowLarge: [
        BoxShadow(
          color: Colors.black.withOpacity(0.6),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ],
      blurAmount: 0,
      useGlass: false,
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
  // THEME: HELL (Light / Clean)
  // ---------------------------------------------------------------------------
  
  static DesignTokens _createHell(_Radii radii) {
    const primary = Color(0xFF007AFF); // iOS Blue
    const secondary = Color(0xFF5856D6); // iOS Purple
    const background = Color(0xFFF2F2F7); // iOS Light Gray Background
    const surface = Color(0xFFFFFFFF);
    const surfaceElevated = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF000000);
    const textSecondary = Color(0xFF8E8E93); // iOS Secondary Label
    const textDisabled = Color(0xFFC7C7CC);
    
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
      success: const Color(0xFF34C759), // iOS Green
      warning: const Color(0xFFFF9500), // iOS Orange
      error: const Color(0xFFFF3B30), // iOS Red
      info: const Color(0xFF5AC8FA), // iOS Teal
      divider: const Color(0xFFC6C6C8),
      cardBorder: const Color(0xFFE5E5EA),
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
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
      shadowSmall: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      shadowMedium: [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
      shadowLarge: [
        BoxShadow(
          color: Colors.black.withOpacity(0.16),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ],
      blurAmount: 0,
      useGlass: false,
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
      animationCurve: Curves.easeInOut,
    );
  }
  
  // ---------------------------------------------------------------------------
  // HELPER: BorderRadius
  // ---------------------------------------------------------------------------
  
  /// Erstellt BorderRadius aus dem Token-Wert
  BorderRadius borderRadiusSmall() => BorderRadius.circular(radiusSmall);
  BorderRadius borderRadiusMedium() => BorderRadius.circular(radiusMedium);
  BorderRadius borderRadiusLarge() => BorderRadius.circular(radiusLarge);
  BorderRadius borderRadiusXLarge() => BorderRadius.circular(radiusXLarge);
  BorderRadius borderRadiusFull() => BorderRadius.circular(radiusFull);
  
  // ---------------------------------------------------------------------------
  // HELPER: Card Decoration
  // ---------------------------------------------------------------------------
  
  /// Standard Card Decoration
  BoxDecoration cardDecoration({
    Color? color,
    List<BoxShadow>? shadow,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: borderRadius ?? borderRadiusMedium(),
      boxShadow: shadow ?? shadowSmall,
      border: Border.all(color: cardBorder, width: 0.5),
    );
  }
  
  /// Glass Card Decoration (für Glass-Theme)
  BoxDecoration glassDecoration({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? overlay,
      borderRadius: borderRadius ?? borderRadiusMedium(),
      border: Border.all(color: cardBorder, width: 1),
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
// EXTENSION: BuildContext
// ============================================================================

/// Extension für einfachen Zugriff auf Design Tokens
extension DesignTokensExtension on BuildContext {
  /// Schnellzugriff auf aktuelle Design Tokens
  DesignTokens get tokens => DesignTokens.current;
}

// ============================================================================
// GLASSMORPHISM WIDGET
// ============================================================================

/// Widget für Glassmorphism-Effekt
class GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final Color? color;
  
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.current;
    
    if (!tokens.useGlass) {
      return Container(
        padding: padding ?? EdgeInsets.all(tokens.spacingM),
        decoration: tokens.cardDecoration(
          borderRadius: borderRadius,
        ),
        child: child,
      );
    }
    
    return ClipRRect(
      borderRadius: borderRadius ?? tokens.borderRadiusMedium(),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: tokens.blurAmount,
          sigmaY: tokens.blurAmount,
        ),
        child: Container(
          padding: padding ?? EdgeInsets.all(tokens.spacingM),
          decoration: tokens.glassDecoration(
            color: color,
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
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
    
    Widget card;
    
    if (tokens.useGlass) {
      card = GlassContainer(
        padding: padding ?? EdgeInsets.all(tokens.spacingM),
        child: child,
      );
    } else {
      card = Container(
        padding: padding ?? EdgeInsets.all(tokens.spacingM),
        decoration: tokens.cardDecoration(shadow: shadow),
        child: child,
      );
    }
    
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
