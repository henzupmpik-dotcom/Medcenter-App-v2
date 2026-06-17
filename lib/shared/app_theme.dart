import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryBlue = Color(0xFF1565C0);
  static const _accentBlue = Color(0xFF42A5F5);
  static const _darkBlue = Color(0xFF0D47A1);
  static const _lightBlue = Color(0xFFE3F2FD);
  static const _surface = Color(0xFFF5F7FA);
  static const _error = Color(0xFFD32F2F);
  static const _success = Color(0xFF2E7D32);
  static const _warning = Color(0xFFF57F17);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryBlue,
          primary: _primaryBlue,
          secondary: _accentBlue,
          surface: Colors.white,
          error: _error,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: _surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primaryBlue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(color: Color(0xFF607D8B)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryBlue,
            side: const BorderSide(color: _primaryBlue),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _primaryBlue),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: _primaryBlue,
          unselectedItemColor: Color(0xFF90A4AE),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _lightBlue,
          labelStyle: const TextStyle(color: _primaryBlue, fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFECEFF1), thickness: 1),
        fontFamily: 'Roboto',
      );

  static ThemeData get dark => ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryBlue,
          brightness: Brightness.dark,
        ),
      );

  // Status colors
  static Color statusColor(String status) {
    switch (status) {
      case 'paid': return _success;
      case 'unpaid': return _error;
      case 'partial': return _warning;
      case 'booked': return _primaryBlue;
      case 'arrived': return _accentBlue;
      case 'in-progress': return _warning;
      case 'done': return _success;
      case 'cancelled': return const Color(0xFF757575);
      case 'active': return _success;
      default: return const Color(0xFF757575);
    }
  }

  static const primaryBlue = _primaryBlue;
  static const accentBlue = _accentBlue;
  static const darkBlue = _darkBlue;
  static const lightBlue = _lightBlue;
  static const background = Color(0xFFF4F6F8);
  static const successGreen = _success;
  static const errorRed = _error;
  static const warningAmber = _warning;
}
