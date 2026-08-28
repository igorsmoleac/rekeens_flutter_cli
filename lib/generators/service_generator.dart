import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_cli/services/template_service.dart';
import 'package:rekeens_cli/utils/project_paths.dart';

class ServiceGenerator {
  final _templateService = const TemplateService();

  Future<void> generate(String featureName, String serviceName) async {
    _validate(featureName, serviceName);
    final featureDir = _getFeatureDir(featureName);
    final targetDir = p.join(featureDir, 'data', 'services');
    if (!Directory(targetDir).existsSync()) {
      Directory(targetDir).createSync(recursive: true);
    }
    final targetPath = p.join(targetDir, '${serviceName}_service.dart');
    if (File(targetPath).existsSync()) {
      throw Exception('Service "$serviceName" already exists.');
    }

    final className = _toPascalCase(serviceName);
    await _templateService.copyTemplate(
      sourceDir: p.join(getPackageRoot(), 'templates', 'features', 'service'),
      targetDir: targetDir,
      variables: {'service_name': serviceName, 'class_name': className},
    );

    print('Service "$serviceName" created in feature "$featureName".');
  }

  void _validate(String featureName, String serviceName) {
    if (featureName.isEmpty || serviceName.isEmpty) {
      throw Exception('Feature name and service name are required.');
    }
    if (!_isSnakeCase(featureName) || !_isSnakeCase(serviceName)) {
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
