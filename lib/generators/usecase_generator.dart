import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

class UseCaseGenerator extends BaseGenerator {
  UseCaseGenerator({
    super.templateService,
    super.templatesRootOverride,
    super.workingDirectory,
  });

  Future<void> generate(
    String featureName,
    String useCaseName, {
    bool force = false,
    bool dryRun = false,
    bool withTests = true,
  }) async {
    if (featureName.isEmpty || useCaseName.isEmpty) {
      throw Exception('Feature name and use case name are required.');
    }
    if (!isSnakeCase(featureName) || !isSnakeCase(useCaseName)) {
      throw Exception('Names must be in snake_case.');
    }

    final featureDir = getFeatureDir(featureName);
    final useCasesDir = p.join(featureDir, 'domain', 'usecases');
    final targetPath = p.join(useCasesDir, '${useCaseName}_usecase.dart');
    checkFileExists(targetPath, 'Use case "$useCaseName"', force: force);

    final testDir = p.join(
      projectDir,
      'test',
      'features',
      featureName,
      'domain',
      'usecases',
    );
    final testPath = p.join(testDir, '${useCaseName}_usecase_test.dart');

    if (dryRun) {
      logDryRun('create use case "$useCaseName"', targetPath);
      if (withTests) {
        logDryRun('create use case test "$useCaseName"', testPath);
      }
      return;
    }

    ensureDirectory(useCasesDir);

    final className = toPascalCase(useCaseName);
    await copyTemplate(
      templateSubPath: 'usecase',
      targetDir: useCasesDir,
      variables: {'usecase_name': useCaseName, 'class_name': className},
    );

    if (withTests) {
      await generateTest(
        testTemplateSubPath: 'usecase',
        testDir: testDir,
        variables: {
          'project_name': getProjectName(),
          'feature_name': featureName,
          'usecase_name': useCaseName,
          'class_name': className,
        },
      );
    }

    logger.success(
      'Use case "$useCaseName" created in feature "$featureName".',
    );
  }
}
