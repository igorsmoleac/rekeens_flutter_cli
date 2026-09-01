import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

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
    bool withTests = true,
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

    final testDir = p.join(
      projectDir,
      'test',
      'features',
      featureName,
      'data',
      'services',
    );
    final testPath = p.join(testDir, '${serviceName}_service_test.dart');

    if (dryRun) {
      logDryRun('create service "$serviceName"', targetPath);
      if (withTests) logDryRun('create service test "$serviceName"', testPath);
      return;
    }

    ensureDirectory(servicesDir);

    final className = toPascalCase(serviceName);
    await copyTemplate(
      templateSubPath: 'service',
      targetDir: servicesDir,
      variables: {'service_name': serviceName, 'class_name': className},
    );

    if (withTests) {
      await generateTest(
        testTemplateSubPath: 'service',
        testDir: testDir,
        variables: {
          'project_name': getProjectName(),
          'feature_name': featureName,
          'service_name': serviceName,
          'class_name': className,
        },
      );
    }

    logger.success('Service "$serviceName" created in feature "$featureName".');
  }
}
