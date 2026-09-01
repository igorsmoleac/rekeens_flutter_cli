import 'package:flutter/material.dart';

/// Centralized typography tokens for the application.
///
/// [fontFamily] is injected via the `--font-family` CLI flag or the
/// `font_family` key in `rekeens.yaml`. When unset, the platform default
/// font is used.
class AppTypography {
  const AppTypography._();

  {{#if has_font}}static const String? fontFamily = '{{font_family}}';{{/if}}{{#unless has_font}}static const String? fontFamily = null;{{/unless}}

  static TextTheme get textTheme => TextTheme(
    // Display
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      fontFamily: fontFamily,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      fontFamily: fontFamily,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      fontFamily: fontFamily,
      height: 1.22,
    ),
    // Headline
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      fontFamily: fontFamily,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      fontFamily: fontFamily,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      fontFamily: fontFamily,
      height: 1.33,
    ),
    // Title
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      fontFamily: fontFamily,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: fontFamily,
      height: 1.5,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: fontFamily,
      height: 1.43,
      letterSpacing: 0.1,
    ),
    // Body
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      fontFamily: fontFamily,
      height: 1.5,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontFamily: fontFamily,
      height: 1.43,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      fontFamily: fontFamily,
      height: 1.33,
      letterSpacing: 0.4,
    ),
    // Label
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: fontFamily,
      height: 1.43,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      fontFamily: fontFamily,
      height: 1.33,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      fontFamily: fontFamily,
      height: 1.45,
      letterSpacing: 0.5,
    ),
  );
}
