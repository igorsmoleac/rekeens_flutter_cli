import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_cli/services/template_service.dart';
import 'package:rekeens_cli/utils/project_paths.dart';

class FeatureGenerator {
  final _templateService = const TemplateService();

  Future<void> generate(String featureName) async {
    if (featureName.isEmpty) {
      throw Exception('Feature name is required.');
    }

    if (!_isSnakeCase(featureName)) {
      throw Exception(
        'Feature name must be in snake_case (lowercase with underscores).',
      );
    }

    final currentDir = Directory.current.path;
    final pubspec = File(p.join(currentDir, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      throw Exception(
        'Not a Flutter/Dart project directory (pubspec.yaml not found).',
      );
    }

    final featureDir = p.join(currentDir, 'lib', 'features', featureName);
    if (Directory(featureDir).existsSync()) {
      throw Exception('Feature "$featureName" already exists.');
    }

    final className = _toPascalCase(featureName);
    final variables = <String, String>{
      'feature_name': featureName,
      'class_name': className,
    };

    final templateDir = p.join(
      getPackageRoot(),
      'templates',
      'features',
      'feature',
    );
    if (!Directory(templateDir).existsSync()) {
      throw Exception('Feature template not found: $templateDir');
    }

    await _templateService.copyTemplate(
      sourceDir: templateDir,
      targetDir: featureDir,
      variables: variables,
    );

    print('Feature "$featureName" created successfully.');
  }

  bool _isSnakeCase(String name) {
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);
  }

  String _toPascalCase(String snakeCase) {
    final parts = snakeCase.split('_');
    return parts.map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1);
    }).join();
  }
}
