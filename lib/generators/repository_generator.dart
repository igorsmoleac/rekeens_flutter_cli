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
    final domainRepositoriesDir = p.join(featureDir, 'domain', 'repositories');
    final dataRepositoriesDir = p.join(featureDir, 'data', 'repositories');
    final interfacePath = p.join(
      domainRepositoriesDir,
      '${repositoryName}_repository.dart',
    );
    final implPath = p.join(
      dataRepositoriesDir,
      '${repositoryName}_repository_impl.dart',
    );
    checkFileExists(
      interfacePath,
      'Repository interface "$repositoryName"',
      force: force,
    );
    checkFileExists(
      implPath,
      'Repository implementation "$repositoryName"',
      force: force,
    );

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
      logDryRun('create repository interface "$repositoryName"', interfacePath);
      logDryRun('create repository implementation "$repositoryName"', implPath);
      if (withTests) {
        logDryRun('create repository test "$repositoryName"', testPath);
      }
      return;
    }

    ensureDirectory(domainRepositoriesDir);
    ensureDirectory(dataRepositoriesDir);

    final className = toPascalCase(repositoryName);
    final variables = <String, String>{
      'repository_name': repositoryName,
      'class_name': className,
    };

    await copyTemplate(
      templateSubPath: 'repository/domain',
      targetDir: domainRepositoriesDir,
      variables: variables,
    );
    await copyTemplate(
      templateSubPath: 'repository/data',
      targetDir: dataRepositoriesDir,
      variables: variables,
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
