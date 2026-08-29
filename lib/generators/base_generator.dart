import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/template_service.dart';
import 'package:rekeens_flutter_cli/utils/project_paths.dart';

abstract class BaseGenerator {
  final TemplateService _templateService;
  final String? templatesRootOverride;
  final String? workingDirectory;

  BaseGenerator({
    TemplateService templateService = const TemplateService(),
    this.templatesRootOverride,
    this.workingDirectory,
  }) : _templateService = templateService;

  String get _projectDir => workingDirectory ?? Directory.current.path;

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

  /// Prints a planned [action] targeting [path] without touching the
  /// filesystem. Used by generators when `dryRun` is enabled.
  void logDryRun(String action, String path) {
    print('DRY RUN: would $action -> $path');
  }

  Future<void> copyTemplate({
    required String templateSubPath,
    required String targetDir,
    required Map<String, String> variables,
  }) async {
    final root = templatesRootOverride ?? getPackageRoot();
    final sourceDir = p.join(root, 'templates', 'features', templateSubPath);
    await _templateService.copyTemplate(
      sourceDir: sourceDir,
      targetDir: targetDir,
      variables: variables,
    );
  }
}
