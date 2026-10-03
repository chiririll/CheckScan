import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0B7A6E);
  static const primarySoft = Color(0xFFE4EEEC);
  static const background = Color(0xFFF4F6F5);
  static const text = Color(0xFF1B1B1B);
  static const muted = Color(0xFF757575);
  static const border = Color(0xFFE4E4E4);
  static const divider = Color(0xFFE8E8E8);
  static const danger = Color(0xFFC62828);
}

class AppShapes {
  static const radius = BorderRadius.all(Radius.circular(10));

  /// White outlined card used by list rows across the app.
  static const card = RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: AppColors.border));
}

class AppText {
  static const title = TextStyle(fontWeight: FontWeight.w600);
  static const muted = TextStyle(color: AppColors.muted);
  static const mutedSmall = TextStyle(color: AppColors.muted, fontSize: 13);
  static const danger = TextStyle(color: AppColors.danger);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
