import 'package:flutter/material.dart';

/// Brand-dependent colors that differ between light and dark themes.
/// Read with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.divider,
    required this.danger,
  });

  final Color primary;
  final Color onPrimary;
  final Color primarySoft;
  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final Color border;
  final Color divider;
  final Color danger;

  static const light = AppPalette(
    primary: Color(0xFF0B7A6E),
    onPrimary: Colors.white,
    primarySoft: Color(0xFFE0F0ED),
    background: Color(0xFFF3F6F5),
    surface: Colors.white,
    text: Color(0xFF16201E),
    muted: Color(0xFF6B7774),
    border: Color(0xFFE3E9E7),
    divider: Color(0xFFE8EDEB),
    danger: Color(0xFFC62828),
  );

  static const dark = AppPalette(
    primary: Color(0xFF4FD1BE),
    onPrimary: Color(0xFF00201C),
    primarySoft: Color(0xFF1B3834),
    background: Color(0xFF0E1413),
    surface: Color(0xFF172120),
    text: Color(0xFFE5ECEA),
    muted: Color(0xFF93A19E),
    border: Color(0xFF263230),
    divider: Color(0xFF212C2A),
    danger: Color(0xFFFF8A80),
  );

  BorderRadius get radius => const BorderRadius.all(Radius.circular(14));

  /// Surface-colored outlined card used by list rows across the app.
  ShapeBorder get cardShape => RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: border));

  @override
  AppPalette copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primarySoft,
    Color? background,
    Color? surface,
    Color? text,
    Color? muted,
    Color? border,
    Color? divider,
    Color? danger,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySoft: primarySoft ?? this.primarySoft,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
