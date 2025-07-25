import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LuxuryTheme {
  static ThemeData get theme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF1A73E8), // Google Blue
      onPrimary: Colors.white,
      secondary: const Color(0xFF34A853), // Google Green
      onSecondary: Colors.white,
      error: const Color(0xFFEA4335), // Google Red
      onError: Colors.white,
      background: const Color(0xFFF8F9FA), // Google light gray
      onBackground: const Color(0xFF202124),
      surface: Colors.white,
      onSurface: const Color(0xFF202124),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A73E8),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A73E8)),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF202124),
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF202124),
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF202124),
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: const Color(0xFF202124),
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF5F6368),
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A73E8),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: Colors.black12,
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const StadiumBorder(),
        splashColor: const Color(0xFF34A853).withOpacity(0.2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: const Color(0xFF5F6368)),
        prefixIconColor: const Color(0xFF1A73E8),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF202124),
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
      highlightColor: const Color(0xFF1A73E8).withOpacity(0.05),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF1A73E8),
      onPrimary: Colors.white,
      secondary: const Color(0xFF34A853),
      onSecondary: Colors.white,
      error: const Color(0xFFEA4335),
      onError: Colors.white,
      background: const Color(0xFF202124),
      onBackground: Colors.white,
      surface: const Color(0xFF292A2D),
      onSurface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF202124),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF292A2D),
        elevation: 1,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A73E8)),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFFB0B3B8),
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A73E8),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF292A2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const StadiumBorder(),
        splashColor: const Color(0xFF34A853).withOpacity(0.2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF292A2D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        prefixIconColor: const Color(0xFF1A73E8),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF292A2D),
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
      highlightColor: const Color(0xFF1A73E8).withOpacity(0.05),
    );
  }
} 