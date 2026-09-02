import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

class EntityGenerator extends BaseGenerator {
  EntityGenerator({
    super.templateService,
    super.templatesRootOverride,
    super.workingDirectory,
  });

  Future<void> generate(
    String featureName,
    String entityName, {
    bool force = false,
    bool dryRun = false,
    bool withTests = true,
  }) async {
    if (featureName.isEmpty || entityName.isEmpty) {
      throw Exception('Feature name and entity name are required.');
    }
    if (!isSnakeCase(featureName) || !isSnakeCase(entityName)) {
      throw Exception('Names must be in snake_case.');
    }

    final featureDir = getFeatureDir(featureName);
    final entitiesDir = p.join(featureDir, 'domain', 'entities');
    final targetPath = p.join(entitiesDir, '${entityName}_entity.dart');
    checkFileExists(targetPath, 'Entity "$entityName"', force: force);

    final testDir = p.join(
      projectDir,
      'test',
      'features',
      featureName,
      'domain',
      'entities',
    );
    final testPath = p.join(testDir, '${entityName}_entity_test.dart');

    if (dryRun) {
      logDryRun('create entity "$entityName"', targetPath);
      if (withTests) logDryRun('create entity test "$entityName"', testPath);
      return;
    }

    ensureDirectory(entitiesDir);

    final className = toPascalCase(entityName);
    await copyTemplate(
      templateSubPath: 'entity',
      targetDir: entitiesDir,
      variables: {'entity_name': entityName, 'class_name': className},
    );

    if (withTests) {
      await generateTest(
        testTemplateSubPath: 'entity',
        testDir: testDir,
        variables: {
          'project_name': getProjectName(),
          'feature_name': featureName,
          'entity_name': entityName,
          'class_name': className,
        },
      );
    }

    logger.success('Entity "$entityName" created in feature "$featureName".');
  }
}
