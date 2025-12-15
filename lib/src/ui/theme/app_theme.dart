/// App Theme Configuration with Dynamic Color Support

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Available theme colors for user selection - 10 carefully curated colors
/// Including pastels, earth tones, and elegant neutrals
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
    // Für jeden Farbton eine harmonische Akzentfarbe
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
