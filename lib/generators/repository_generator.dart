import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

class RepositoryGenerator extends BaseGenerator {
  RepositoryGenerator({
    super.templateService,
    super.templatesRootOverride,
    super.workingDirectory,
  });

  Future<void> generate(
    String featureName,
    String repositoryName, {
    bool force = false,
    bool dryRun = false,
    bool withTests = true,
  }) async {
    if (featureName.isEmpty || repositoryName.isEmpty) {
      throw Exception('Feature name and repository name are required.');
    }
    if (!isSnakeCase(featureName) || !isSnakeCase(repositoryName)) {
      throw Exception('Names must be in snake_case.');
    }

    final featureDir = getFeatureDir(featureName);
    final repositoriesDir = p.join(featureDir, 'data', 'repositories');
    final targetPath = p.join(
      repositoriesDir,
      '${repositoryName}_repository.dart',
    );
    checkFileExists(targetPath, 'Repository "$repositoryName"', force: force);

    final testDir = p.join(
      projectDir,
      'test',
      'features',
      featureName,
      'data',
      'repositories',
    );
    final testPath = p.join(testDir, '${repositoryName}_repository_test.dart');

    if (dryRun) {
      logDryRun('create repository "$repositoryName"', targetPath);
      if (withTests) {
        logDryRun('create repository test "$repositoryName"', testPath);
      }
      return;
    }

    ensureDirectory(repositoriesDir);

    final className = toPascalCase(repositoryName);
    await copyTemplate(
      templateSubPath: 'repository',
      targetDir: repositoriesDir,
      variables: {'repository_name': repositoryName, 'class_name': className},
    );

    if (withTests) {
      await generateTest(
        testTemplateSubPath: 'repository',
        testDir: testDir,
        variables: {
          'project_name': getProjectName(),
          'feature_name': featureName,
          'repository_name': repositoryName,
          'class_name': className,
        },
      );
    }

    logger.success(
      'Repository "$repositoryName" created in feature "$featureName".',
    );
  }
}
