/// Le thème de l'application : les couleurs du logo et de la bannière.
///
/// Vert nuit profond, accent sarcelle pris dans le ruban du V, Syne pour les
/// titres (jamais pour des chiffres, ses numéraux sont mauvais) et Space
/// Grotesk pour le reste, nombres en chasse fixe.
library;

import 'package:flutter/material.dart';

abstract final class K {
  // Fonds, du plus profond au plus proche
  static const bg = Color(0xFF040C0B);
  static const surface = Color(0xFF0A1715);
  static const surface2 = Color(0xFF0F201D);
  static const surface3 = Color(0xFF162C28);
  static const border = Color(0x14FFFFFF);
  static const borderStrong = Color(0x26FFFFFF);

  // Texte
  static const text = Color(0xFFF1F5F9);
  static const textSoft = Color(0xFFC9D6D3);
  static const muted = Color(0xFF94A3B0);
  static const faint = Color(0xFF66767A);

  // Accent, pris dans le logo
  static const accent = Color(0xFF39D2C0);
  static const accentPale = Color(0xFFA7F3E6);
  static const accentProfond = Color(0xFF1C8F83);
  static const accentSoft = Color(0x2439D2C0);
  static const surAccent = Color(0xFF02221E);

  // États
  static const or = Color(0xFFF5C451);
  static const argent = Color(0xFFC3CCD6);
  static const bronze = Color(0xFFD9925B);
  static const flamme = Color(0xFFFF8A4C);
  static const flammeSoft = Color(0x24FF8A4C);
  static const danger = Color(0xFFFF6B81);
  static const dangerSoft = Color(0x1FFF6B81);

  static const radius = 14.0;
  static const radiusLg = 22.0;

  static const degrade = LinearGradient(
    colors: [accentPale, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Durées et courbes
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 520);
  static const ease = Curves.easeOutCubic;
  static const spring = Curves.easeOutQuart;

  /// Titres : Syne. Aucun chiffre dedans.
  static TextStyle display(double size, {FontWeight weight = FontWeight.w700, Color color = text}) => TextStyle(
    fontFamily: 'Syne',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.15,
    letterSpacing: -0.3,
  );

  /// Nombres : Space Grotesk en chasse fixe.
  static TextStyle number(double size, {Color color = text, FontWeight weight = FontWeight.w700}) => TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1,
    letterSpacing: -size * 0.02,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Petites capitales espacées, pour les étiquettes.
  static const etiquette = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: muted,
  );
}

ThemeData construireTheme() {
  const scheme = ColorScheme.dark(
    primary: K.accent,
    onPrimary: K.surAccent,
    secondary: K.accentPale,
    surface: K.surface,
    onSurface: K.text,
    error: K.danger,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'SpaceGrotesk',
    brightness: Brightness.dark,
  );

  OutlineInputBorder contour(Color color, [double width = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(K.radius),
    borderSide: BorderSide(color: color, width: width),
  );

  return base.copyWith(
    scaffoldBackgroundColor: K.bg,
    splashFactory: InkSparkle.splashFactory,
    textTheme: base.textTheme.apply(bodyColor: K.text, displayColor: K.text, fontFamily: 'SpaceGrotesk'),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.25),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: const TextStyle(color: K.faint),
      labelStyle: const TextStyle(color: K.muted),
      floatingLabelStyle: const TextStyle(color: K.accent, fontWeight: FontWeight.w600),
      prefixIconColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.focused) ? K.accent : K.faint),
      suffixIconColor: K.muted,
      border: contour(K.borderStrong),
      enabledBorder: contour(K.borderStrong),
      focusedBorder: contour(K.accent, 1.6),
      errorBorder: contour(K.danger),
      focusedErrorBorder: contour(K.danger, 1.6),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: K.surface3,
      contentTextStyle: const TextStyle(color: K.text, fontWeight: FontWeight.w500, fontFamily: 'SpaceGrotesk'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.radius)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: K.surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.radiusLg)),
      titleTextStyle: K.display(20),
      contentTextStyle: const TextStyle(color: K.textSoft, fontSize: 15, height: 1.45, fontFamily: 'SpaceGrotesk'),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? K.surAccent : K.muted),
      trackColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? K.accent : K.surface3),
      trackOutlineColor: WidgetStateColor.resolveWith(
        (s) => s.contains(WidgetState.selected) ? K.accent : K.borderStrong,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: K.accent),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: K.accent, selectionHandleColor: K.accent),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}
