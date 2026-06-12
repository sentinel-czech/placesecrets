import 'package:flutter/material.dart';

abstract class AppTheme {
  static const _primaryColor = Color(0xFF2D6A4F);
  static const _goldColor = Color(0xFFB8960C);

  static ColorScheme get _lightScheme => ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      );

  static ColorScheme get _darkScheme => ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
      );

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: _lightScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: _lightScheme.surface,
          foregroundColor: _lightScheme.onSurface,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: _darkScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: _darkScheme.surface,
          foregroundColor: _darkScheme.onSurface,
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _darkScheme.primary,
          foregroundColor: _darkScheme.onPrimary,
        ),
      );

  static const Color gold = _goldColor;
  static const Color primary = _primaryColor;
}
