import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/template_service.dart';
import 'package:rekeens_flutter_cli/utils/project_paths.dart';

class RepositoryGenerator {
  final _templateService = const TemplateService();

  Future<void> generate(String featureName, String repositoryName) async {
    _validate(featureName, repositoryName);
    final featureDir = _getFeatureDir(featureName);
    final targetDir = p.join(featureDir, 'data', 'repositories');
    final targetPath = p.join(targetDir, '${repositoryName}_repository.dart');
    _checkExists(targetPath, repositoryName);

    final className = _toPascalCase(repositoryName);
    final variables = {
      'repository_name': repositoryName,
      'class_name': className,
    };

    await _templateService.copyTemplate(
      sourceDir: p.join(
        getPackageRoot(),
        'templates',
        'features',
        'repository',
      ),
      targetDir: targetDir,
      variables: variables,
    );

    print('Repository "$repositoryName" created in feature "$featureName".');
  }

  void _validate(String featureName, String repositoryName) {
    if (featureName.isEmpty || repositoryName.isEmpty) {
      throw Exception('Feature name and repository name are required.');
    }
    if (!_isSnakeCase(featureName) || !_isSnakeCase(repositoryName)) {
      throw Exception('Names must be in snake_case.');
    }
  }

  String _getFeatureDir(String featureName) {
    final dir = Directory(
      p.join(Directory.current.path, 'lib', 'features', featureName),
    );
    if (!dir.existsSync()) {
      throw Exception('Feature "$featureName" does not exist.');
    }
    return dir.path;
  }

  void _checkExists(String path, String name) {
    if (File(path).existsSync()) {
      throw Exception('Repository "$name" already exists.');
    }
  }

  bool _isSnakeCase(String name) => RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);

  String _toPascalCase(String snakeCase) {
    final parts = snakeCase.split('_');
    return parts
        .map(
          (part) =>
              part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1),
        )
        .join();
  }
}
