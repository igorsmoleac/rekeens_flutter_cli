import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/template_service.dart';
import 'package:test/test.dart';

/// Tests that the base theme templates (app_colors.dart, app_typography.dart,
/// app_theme.dart) render correctly with seed_color / font_family / theme
/// variables and conditions.
///
/// These templates are applied by ProjectScaffolder._applyTemplate (not
/// ProjectFileWriter), so we test the rendering via TemplateService directly
/// against the real template files.
void main() {
  late Directory tempDir;
  const templateService = TemplateService();
  late String templatesRoot;

  setUpAll(() {
    templatesRoot = Directory.current.path;
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('theme_template_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  String baseThemeDir() =>
      p.join(templatesRoot, 'templates', 'base', 'lib', 'app', 'theme');

  Future<String> renderFile(
    String fileName, {
    required String seedColor,
    required String fontFamily,
    required String useMaterial3,
  }) async {
    final sourcePath = p.join(baseThemeDir(), fileName);
    final targetPath = p.join(tempDir.path, fileName);
    await templateService.renderFile(
      sourcePath: sourcePath,
      targetPath: targetPath,
      variables: {
        'project_name': 'test_app',
        'seed_color': seedColor,
        'font_family': fontFamily,
        'use_material3': useMaterial3,
      },
      conditions: {
        'has_font': fontFamily.isNotEmpty,
        'material3': useMaterial3 == 'true',
      },
    );
    return File(targetPath).readAsStringSync();
  }

  group('app_colors.dart template', () {
    test('substitutes seed_color hex value', () async {
      final content = await renderFile(
        'app_colors.dart',
        seedColor: '0xFF6750A4',
        fontFamily: '',
        useMaterial3: 'true',
      );
      expect(
        content,
        contains('static const Color seedColor = Color(0xFF6750A4);'),
      );
      expect(content, contains('class AppColors'));
      // Semantic tokens present
      expect(content, contains('static const Color error'));
      expect(content, contains('static const Color success'));
      expect(content, contains('static const Color warning'));
      // Surface tokens
      expect(content, contains('static const Color surface'));
      expect(content, contains('static const Color darkSurface'));
    });

    test('works with different seed color', () async {
      final content = await renderFile(
        'app_colors.dart',
        seedColor: '0xFFFF5722',
        fontFamily: '',
        useMaterial3: 'true',
      );
      expect(content, contains('Color(0xFFFF5722)'));
    });
  });

  group('app_typography.dart template', () {
    test('includes font family when provided', () async {
      final content = await renderFile(
        'app_typography.dart',
        seedColor: '0xFF2196F3',
        fontFamily: 'Roboto',
        useMaterial3: 'true',
      );
      expect(content, contains("static const String fontFamily = 'Roboto';"));
      // All TextTheme styles reference fontFamily
      expect(content, contains('fontFamily: fontFamily'));
      // Full TextTheme — all 15 styles
      expect(content, contains('displayLarge'));
      expect(content, contains('displayMedium'));
      expect(content, contains('displaySmall'));
      expect(content, contains('headlineLarge'));
      expect(content, contains('headlineMedium'));
      expect(content, contains('headlineSmall'));
      expect(content, contains('titleLarge'));
      expect(content, contains('titleMedium'));
      expect(content, contains('titleSmall'));
      expect(content, contains('bodyLarge'));
      expect(content, contains('bodyMedium'));
      expect(content, contains('bodySmall'));
      expect(content, contains('labelLarge'));
      expect(content, contains('labelMedium'));
      expect(content, contains('labelSmall'));
    });

    test('uses null fontFamily when not provided', () async {
      final content = await renderFile(
        'app_typography.dart',
        seedColor: '0xFF2196F3',
        fontFamily: '',
        useMaterial3: 'true',
      );
      expect(content, contains('static const String? fontFamily = null;'));
      expect(content, contains('fontFamily: fontFamily'));
    });
  });

  group('app_theme.dart template', () {
    test('uses useMaterial3: true for material3', () async {
      final content = await renderFile(
        'app_theme.dart',
        seedColor: '0xFF6750A4',
        fontFamily: '',
        useMaterial3: 'true',
      );
      expect(content, contains('useMaterial3: true'));
      expect(content, contains('AppColors.seedColor'));
      expect(content, contains('AppTypography.textTheme'));
      expect(content, contains('Brightness.light'));
      expect(content, contains('Brightness.dark'));
    });

    test('uses useMaterial3: false for material2', () async {
      final content = await renderFile(
        'app_theme.dart',
        seedColor: '0xFF2196F3',
        fontFamily: '',
        useMaterial3: 'false',
      );
      expect(content, contains('useMaterial3: false'));
      expect(content, contains('AppColors.seedColor'));
    });
  });
}
