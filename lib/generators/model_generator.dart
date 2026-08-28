import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/template_service.dart';
import 'package:rekeens_flutter_cli/utils/project_paths.dart';

class ModelGenerator {
  final _templateService = const TemplateService();

  Future<void> generate(String featureName, String modelName) async {
    if (featureName.isEmpty || modelName.isEmpty) {
      throw Exception('Feature name and model name are required.');
    }

    if (!_isSnakeCase(featureName) || !_isSnakeCase(modelName)) {
      throw Exception(
        'Names must be in snake_case (lowercase with underscores).',
      );
    }

    final currentDir = Directory.current.path;
    final featureDir = p.join(currentDir, 'lib', 'features', featureName);
    if (!Directory(featureDir).existsSync()) {
      throw Exception('Feature "$featureName" does not exist.');
    }

    final modelsDir = p.join(featureDir, 'data', 'models');
    final targetPath = p.join(modelsDir, '${modelName}_model.dart');
    if (File(targetPath).existsSync()) {
      throw Exception(
        'Model "$modelName" already exists in feature "$featureName".',
      );
    }

    final className = _toPascalCase(modelName);
    final variables = <String, String>{
      'model_name': modelName,
      'class_name': className,
    };

    final templateDir = p.join(
      getPackageRoot(),
      'templates',
      'features',
      'model',
    );

    await _templateService.copyTemplate(
      sourceDir: templateDir,
      targetDir: modelsDir,
      variables: variables,
    );

    print('Model "$modelName" created in feature "$featureName".');
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
