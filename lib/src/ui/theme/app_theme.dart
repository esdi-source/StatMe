/// App Theme Configuration - Integration mit Design Tokens
/// 
/// Erstellt Flutter ThemeData basierend auf den aktuellen Design Tokens.
/// Diese Datei dient als Brücke zwischen dem Token-System und Flutter's
/// Material Theme System.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// Legacy ThemeColor enum für Abwärtskompatibilität
/// @deprecated Verwende stattdessen ThemePreset und ShapeStyle
enum ThemeColor {
  // Pastell-Farben
  lavender(Color(0xFFB8A9C9), 'Lavendel', 'Sanft und beruhigend'),
  sage(Color(0xFFB2C9AD), 'Salbei', 'Natürlich und frisch'),
  blush(Color(0xFFE8C4C4), 'Rosé', 'Elegant und warm'),
  sky(Color(0xFFA7C5EB), 'Himmelblau', 'Klar und freundlich'),
  mint(Color(0xFFB5D8CC), 'Mint', 'Erfrischend und modern'),
  
  // Erdtöne / Beige / Braun
  caramel(Color(0xFFD4A574), 'Karamell', 'Warm und gemütlich'),
  terracotta(Color(0xFFCB8B73), 'Terracotta', 'Erdverbunden'),
  mocha(Color(0xFF9C7E6E), 'Mokka', 'Elegant und zeitlos'),
  sand(Color(0xFFD9CAB3), 'Sand', 'Natürlich und schlicht'),
  olive(Color(0xFF8B9A71), 'Olive', 'Klassisch und ruhig');

  final Color color;
  final String label;
  final String description;
  const ThemeColor(this.color, this.label, this.description);
  
  /// Findet eine ThemeColor anhand des Color-Wertes
  static ThemeColor? fromColor(Color color) {
    for (final themeColor in ThemeColor.values) {
      if (themeColor.color.value == color.value) {
        return themeColor;
      }
    }
    return null;
  }
  
  /// Liefert eine passende Akzentfarbe
  Color get accentColor {
    switch (this) {
      case ThemeColor.lavender:
        return const Color(0xFF7B68A6);
      case ThemeColor.sage:
        return const Color(0xFF6B8E65);
      case ThemeColor.blush:
        return const Color(0xFFB88A8A);
      case ThemeColor.sky:
        return const Color(0xFF5B8DC9);
      case ThemeColor.mint:
        return const Color(0xFF6BA893);
      case ThemeColor.caramel:
        return const Color(0xFFA67C52);
      case ThemeColor.terracotta:
        return const Color(0xFFA66B55);
      case ThemeColor.mocha:
        return const Color(0xFF6D564A);
      case ThemeColor.sand:
        return const Color(0xFFB5A48C);
      case ThemeColor.olive:
        return const Color(0xFF6B7A55);
    }
  }
  
  /// Liefert eine passende Container-Farbe (heller)
  Color get containerColor {
    return Color.lerp(color, Colors.white, 0.7)!;
  }
  
  /// Liefert eine passende dunkle Variante
  Color get darkVariant {
    return Color.lerp(color, Colors.black, 0.3)!;
  }
}

class AppTheme {
  static const Color secondaryColor = Color(0xFF2196F3);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  
  /// Erstellt ein ThemeData basierend auf den aktuellen Design Tokens
  static ThemeData fromTokens(DesignTokens tokens) {
    final isDark = tokens.background.computeLuminance() < 0.5;
    
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: tokens.primary,
        onPrimary: _contrastColor(tokens.primary),
        secondary: tokens.secondary,
        onSecondary: _contrastColor(tokens.secondary),
        error: tokens.error,
        onError: _contrastColor(tokens.error),
        surface: tokens.surface,
        onSurface: tokens.textPrimary,
      ),
      scaffoldBackgroundColor: tokens.background,
      textTheme: _buildTextTheme(tokens, isDark),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: tokens.titleLarge.copyWith(color: tokens.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          side: BorderSide(color: tokens.cardBorder, width: 0.5),
        ),
        shadowColor: tokens.shadowSmall.isNotEmpty 
            ? tokens.shadowSmall.first.color 
            : Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: _contrastColor(tokens.primary),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusSmall),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacingL,
            vertical: tokens.spacingM,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusSmall),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacingM,
            vertical: tokens.spacingS,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.primary,
          side: BorderSide(color: tokens.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusSmall),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacingL,
            vertical: tokens.spacingM,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? tokens.surfaceElevated : tokens.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          borderSide: BorderSide(color: tokens.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          borderSide: BorderSide(color: tokens.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          borderSide: BorderSide(color: tokens.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          borderSide: BorderSide(color: tokens.error),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spacingM,
          vertical: tokens.spacingS,
        ),
        labelStyle: tokens.bodyMedium,
        hintStyle: tokens.bodyMedium.copyWith(color: tokens.textDisabled),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.divider,
        thickness: 0.5,
        space: tokens.spacingM,
      ),
      iconTheme: IconThemeData(
        color: tokens.textSecondary,
        size: 24,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.primary,
        foregroundColor: _contrastColor(tokens.primary),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surface,
        indicatorColor: tokens.primary.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tokens.labelMedium.copyWith(color: tokens.primary);
          }
          return tokens.labelMedium.copyWith(color: tokens.textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: tokens.primary);
          }
          return IconThemeData(color: tokens.textSecondary);
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.radiusXLarge),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
        ),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? tokens.surfaceElevated : tokens.textPrimary,
        contentTextStyle: tokens.bodyMedium.copyWith(
          color: isDark ? tokens.textPrimary : tokens.background,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surface,
        selectedColor: tokens.primary.withOpacity(0.2),
        labelStyle: tokens.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusFull),
          side: BorderSide(color: tokens.divider),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: tokens.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tokens.primary;
          }
          return tokens.textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tokens.primary.withOpacity(0.3);
          }
          return tokens.divider;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: tokens.primary,
        inactiveTrackColor: tokens.divider,
        thumbColor: tokens.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.primary,
        linearTrackColor: tokens.divider,
        circularTrackColor: tokens.divider,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: tokens.primary,
        unselectedLabelColor: tokens.textSecondary,
        indicatorColor: tokens.primary,
        labelStyle: tokens.labelLarge,
        unselectedLabelStyle: tokens.labelLarge,
      ),
    );
  }
  
  /// Erstellt TextTheme basierend auf Tokens
  static TextTheme _buildTextTheme(DesignTokens tokens, bool isDark) {
    return TextTheme(
      displayLarge: tokens.displayLarge,
      displayMedium: tokens.displayMedium,
      displaySmall: tokens.displaySmall,
      headlineLarge: tokens.headlineLarge,
      headlineMedium: tokens.headlineMedium,
      headlineSmall: tokens.headlineSmall,
      titleLarge: tokens.titleLarge,
      titleMedium: tokens.titleMedium,
      titleSmall: tokens.titleSmall,
      bodyLarge: tokens.bodyLarge,
      bodyMedium: tokens.bodyMedium,
      bodySmall: tokens.bodySmall,
      labelLarge: tokens.labelLarge,
      labelMedium: tokens.labelMedium,
      labelSmall: tokens.labelSmall,
    );
  }
  
  /// Berechnet die Kontrastfarbe (Schwarz oder Weiß)
  static Color _contrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
  
  // ---------------------------------------------------------------------------
  // LEGACY METHODS (für Abwärtskompatibilität)
  // ---------------------------------------------------------------------------
  
  /// @deprecated Verwende stattdessen fromTokens()
  static ThemeData lightTheme(Color seedColor) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedIconTheme: IconThemeData(color: seedColor),
        selectedLabelTextStyle: TextStyle(
          color: seedColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
      ),
    );
  }
  
  /// @deprecated Verwende stattdessen fromTokens()
  static ThemeData darkTheme(Color seedColor) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey.shade900,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF2D2D2D),
        selectedIconTheme: IconThemeData(color: seedColor),
        selectedLabelTextStyle: TextStyle(
          color: seedColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
