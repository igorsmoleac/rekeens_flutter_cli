import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Application theme built from [AppColors] and [AppTypography] tokens.
class AppTheme {
  const AppTheme._();

  // dart format off
  static ThemeData get light => ThemeData(
    useMaterial3: {{use_material3}},
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.seedColor,
      brightness: Brightness.light,
    ),
    textTheme: AppTypography.textTheme,
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: {{use_material3}},
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.seedColor,
      brightness: Brightness.dark,
    ),
    textTheme: AppTypography.textTheme,
  );
  // dart format on
}
