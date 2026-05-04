import 'package:flutter/material.dart';
import 'package:appsmarketplace/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light, // ← terang
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: AppColors.primary,
        primary: AppColors.primary, // ← biru tua
        surface: AppColors.surface, // ← putih
      ),
      scaffoldBackgroundColor: AppColors.background, // ← abu muda
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary, // ← biru tua
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark, // ← gelap
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.accent,
        primary: AppColors.accent, // ← biru muda
        surface: AppColors.darkSurface, // ← abu gelap
      ),
      scaffoldBackgroundColor: AppColors.darkBackground, // ← hitam
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface, // ← abu gelap
        foregroundColor: Colors.white,
      ),
      // ...
    );
  }
}
