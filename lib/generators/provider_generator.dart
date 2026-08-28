import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_cli/services/template_service.dart';
import 'package:rekeens_cli/utils/project_paths.dart';

class ProviderGenerator {
  final _templateService = const TemplateService();

  Future<void> generate(String featureName, String providerName) async {
    _validate(featureName, providerName);
    final featureDir = _getFeatureDir(featureName);
    final targetDir = p.join(featureDir, 'presentation', 'providers');
    if (!Directory(targetDir).existsSync()) {
      Directory(targetDir).createSync(recursive: true);
    }
    final targetPath = p.join(targetDir, '${providerName}_provider.dart');
    if (File(targetPath).existsSync()) {
      throw Exception('Provider "$providerName" already exists.');
    }

    final className = _toPascalCase(providerName);
    await _templateService.copyTemplate(
      sourceDir: p.join(getPackageRoot(), 'templates', 'features', 'provider'),
      targetDir: targetDir,
      variables: {'provider_name': providerName, 'class_name': className},
    );

    print('Provider "$providerName" created in feature "$featureName".');
  }

  void _validate(String featureName, String providerName) {
    if (featureName.isEmpty || providerName.isEmpty) {
      throw Exception('Feature name and provider name are required.');
    }
    if (!_isSnakeCase(featureName) || !_isSnakeCase(providerName)) {
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
