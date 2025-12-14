/// App Theme Configuration with Dynamic Color Support

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Available theme colors for user selection
enum ThemeColor {
  green(Color(0xFF4CAF50), 'Grün'),
  blue(Color(0xFF2196F3), 'Blau'),
  purple(Color(0xFF9C27B0), 'Lila'),
  orange(Color(0xFFFF9800), 'Orange'),
  red(Color(0xFFF44336), 'Rot'),
  pink(Color(0xFFE91E63), 'Pink'),
  teal(Color(0xFF009688), 'Türkis'),
  indigo(Color(0xFF3F51B5), 'Indigo'),
  cyan(Color(0xFF00BCD4), 'Cyan'),
  amber(Color(0xFFFFC107), 'Bernstein');

  final Color color;
  final String label;
  const ThemeColor(this.color, this.label);
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
