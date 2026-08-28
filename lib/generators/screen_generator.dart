import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/template_service.dart';
import 'package:rekeens_flutter_cli/utils/project_paths.dart';

class ScreenGenerator {
  final _templateService = const TemplateService();

  Future<void> generate(String featureName, String screenName) async {
    if (featureName.isEmpty || screenName.isEmpty) {
      throw Exception('Feature name and screen name are required.');
    }

    if (!_isSnakeCase(featureName) || !_isSnakeCase(screenName)) {
      throw Exception(
        'Names must be in snake_case (lowercase with underscores).',
      );
    }

    final currentDir = Directory.current.path;
    final featureDir = p.join(currentDir, 'lib', 'features', featureName);
    if (!Directory(featureDir).existsSync()) {
      throw Exception('Feature "$featureName" does not exist.');
    }

    final pagesDir = p.join(featureDir, 'presentation', 'pages');
    final targetPath = p.join(pagesDir, '${screenName}_screen.dart');
    if (File(targetPath).existsSync()) {
      throw Exception(
        'Screen "$screenName" already exists in feature "$featureName".',
      );
    }

    final className = _toPascalCase(screenName) + 'Screen';
    final variables = <String, String>{
      'screen_name': screenName,
      'class_name': className,
    };

    final templateDir = p.join(
      getPackageRoot(),
      'templates',
      'features',
      'screen',
    );

    await _templateService.copyTemplate(
      sourceDir: templateDir,
      targetDir: pagesDir,
      variables: variables,
    );

    print('Screen "$screenName" created in feature "$featureName".');
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
