import 'package:flutter/material.dart';

import 'palette.dart';

export 'palette.dart';

/// Text styles that follow the active palette.
class AppText {
  static const title = TextStyle(fontWeight: FontWeight.w600);

  static TextStyle muted(BuildContext context) => TextStyle(color: context.palette.muted);
  static TextStyle mutedSmall(BuildContext context) => TextStyle(color: context.palette.muted, fontSize: 13);
  static TextStyle danger(BuildContext context) => TextStyle(color: context.palette.danger);
}

ThemeData buildAppTheme([Brightness brightness = Brightness.light]) {
  final palette = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppPalette.light.primary,
    brightness: brightness,
  ).copyWith(
    primary: palette.primary,
    onPrimary: palette.onPrimary,
    surface: palette.surface,
    onSurface: palette.text,
    error: palette.danger,
    outlineVariant: palette.border,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    fontFamily: 'Roboto',
    splashFactory: InkSparkle.splashFactory,
    extensions: [palette],
  );
  const transitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
    },
  );
  return base.copyWith(
    pageTransitionsTheme: transitions,
    dividerTheme: DividerThemeData(color: palette.divider, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.text,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(color: palette.text, fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: palette.primary)),
    tabBarTheme: TabBarThemeData(
      labelColor: palette.primary,
      unselectedLabelColor: palette.muted,
      indicatorColor: palette.primary,
      dividerColor: palette.divider,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      border: OutlineInputBorder(borderRadius: palette.radius, borderSide: BorderSide(color: palette.border)),
      enabledBorder: OutlineInputBorder(borderRadius: palette.radius, borderSide: BorderSide(color: palette.border)),
      focusedBorder: OutlineInputBorder(borderRadius: palette.radius, borderSide: BorderSide(color: palette.primary, width: 1.6)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.text,
      contentTextStyle: TextStyle(color: palette.background),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.primary),
  );
}
