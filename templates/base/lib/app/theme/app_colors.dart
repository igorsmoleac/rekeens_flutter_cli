import 'package:flutter/material.dart';

/// Centralized color tokens for the application.
///
/// [seedColor] drives [ColorScheme.fromSeed] in [AppTheme]. Override it
/// via the `--seed-color` CLI flag or the `seed_color` key in
/// `rekeens.yaml`.
class AppColors {
  const AppColors._();

  /// Brand seed color — drives the Material 3 color scheme.
  // dart format off
  static const Color seedColor = Color({{seed_color}});
  // dart format on

  // ── Brand ──
  static const Color primary = seedColor;
  static const Color secondary = Color(0xFF03DAC6);
  static const Color tertiary = Color(0xFF018786);

  // ── Semantic ──
  static const Color error = Color(0xFFB00020);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  // ── Surfaces (light) ──
  static const Color surface = Color(0xFFFFFBFE);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // ── Surfaces (dark) ──
  static const Color darkSurface = Color(0xFF1C1B1F);
  static const Color darkOnSurface = Color(0xFFE6E1E5);
  static const Color darkSurfaceVariant = Color(0xFF49454F);
  static const Color darkOnSurfaceVariant = Color(0xFFCAC4D0);

  // ── Outlines & dividers ──
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);
  static const Color divider = Color(0x1F1C1B1F);

  // ── Utility ──
  static const Color scrim = Color(0xFF000000);
  static const Color shadow = Color(0xFF000000);
}
