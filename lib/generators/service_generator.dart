import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';

class ServiceGenerator extends BaseGenerator {
  ServiceGenerator({
    super.templateService,
    super.templatesRootOverride,
    super.workingDirectory,
  });

  Future<void> generate(
    String featureName,
    String serviceName, {
    bool force = false,
    bool dryRun = false,
  }) async {
    if (featureName.isEmpty || serviceName.isEmpty) {
      throw Exception('Feature name and service name are required.');
    }
    if (!isSnakeCase(featureName) || !isSnakeCase(serviceName)) {
      throw Exception('Names must be in snake_case.');
    }

    final featureDir = getFeatureDir(featureName);
    final servicesDir = p.join(featureDir, 'data', 'services');
    final targetPath = p.join(servicesDir, '${serviceName}_service.dart');
    checkFileExists(targetPath, 'Service "$serviceName"', force: force);

    if (dryRun) {
      logDryRun('create service "$serviceName"', targetPath);
      return;
    }

    ensureDirectory(servicesDir);

    final className = toPascalCase(serviceName);
    await copyTemplate(
      templateSubPath: 'service',
      targetDir: servicesDir,
      variables: {'service_name': serviceName, 'class_name': className},
    );

    print('Service "$serviceName" created in feature "$featureName".');
  }
}
