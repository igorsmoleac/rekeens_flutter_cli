import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/template_service.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';
import 'package:rekeens_flutter_cli/utils/template_resolver.dart';

abstract class BaseGenerator {
  BaseGenerator({
    this._templateService = const TemplateService(),
    this._templateResolver = const TemplateResolver(),
    this.templatesRootOverride,
    this.workingDirectory,
  });
  final TemplateService _templateService;
  final TemplateResolver _templateResolver;
  final String? templatesRootOverride;
  final String? workingDirectory;

  String get _projectDir => workingDirectory ?? Directory.current.path;

  /// Protected accessor for the project directory path.
  String get projectDir => _projectDir;

  bool isSnakeCase(String name) => RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);

  String toPascalCase(String snakeCase) {
    final parts = snakeCase.split('_');
    return parts
        .map(
          (part) =>
              part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1),
        )
        .join();
  }

  String detectStateManagement() {
    final pubspecFile = File(p.join(_projectDir, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return 'riverpod';

    final content = pubspecFile.readAsStringSync();
    if (content.contains('flutter_bloc')) return 'bloc';
    if (content.contains('flutter_riverpod')) return 'riverpod';
    return 'riverpod';
  }

  String getFeatureDir(String featureName) {
    final dir = Directory(p.join(_projectDir, 'lib', 'features', featureName));
    if (!dir.existsSync()) {
      throw Exception('Feature "$featureName" does not exist.');
    }
    return dir.path;
  }

  String getNewFeatureDir(String featureName) {
    return p.join(_projectDir, 'lib', 'features', featureName);
  }

  void ensureDirectory(String path) {
    Directory(path).createSync(recursive: true);
  }

  void checkFileExists(String path, String entityName, {bool force = false}) {
    if (File(path).existsSync() && !force) {
      throw Exception(
        '$entityName already exists at $path. Use --force to overwrite.',
      );
    }
  }

  void logDryRun(String action, String path) {
    logger.warn('DRY RUN: would $action -> $path');
  }

  Future<void> copyTemplate({
    required String templateSubPath,
    required String targetDir,
    required Map<String, String> variables,
    Map<String, List<Map<String, String>>>? lists,
    String category = 'features',
  }) async {
    final sourceDir = await _templateResolver.resolve(
      category: category,
      subPath: templateSubPath,
      workingDirectory: workingDirectory,
      packageRootOverride: templatesRootOverride,
    );
    await _templateService.copyTemplate(
      sourceDir: sourceDir,
      targetDir: targetDir,
      variables: variables,
      lists: lists,
    );
  }

  /// Generates a test file from a test template under `templates/tests/`.
  ///
  /// [testTemplateSubPath] is the subdirectory under `templates/tests/`
  /// (e.g. `model`). [testDir] is the target directory under `test/`.
  /// [variables] must include all placeholders needed by the test template
  /// (typically `project_name`, `feature_name`, `class_name`, and the
  /// entity-specific name like `model_name`).
  Future<void> generateTest({
    required String testTemplateSubPath,
    required String testDir,
    required Map<String, String> variables,
  }) async {
    ensureDirectory(testDir);
    await copyTemplate(
      templateSubPath: testTemplateSubPath,
      targetDir: testDir,
      variables: variables,
      category: 'tests',
    );
  }

  /// Returns the project name from `pubspec.yaml`.
  String getProjectName() {
    final pubspecFile = File(p.join(_projectDir, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return 'app';
    final content = pubspecFile.readAsStringSync();
    final match = RegExp(
      r'^name:\s*(.+)$',
      multiLine: true,
    ).firstMatch(content);
    return match?.group(1)?.trim() ?? 'app';
  }
}
