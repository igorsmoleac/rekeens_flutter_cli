import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';
import 'package:rekeens_flutter_cli/services/router_updater.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

class FeatureGenerator extends BaseGenerator {
  FeatureGenerator({
    super.templateService,
    super.templatesRootOverride,
    super.workingDirectory,
    RouterUpdater? routerUpdater,
  }) : _routerUpdater =
           routerUpdater ?? RouterUpdater(workingDirectory: workingDirectory);

  final RouterUpdater _routerUpdater;

  Future<void> generate(
    String featureName, {
    bool force = false,
    bool dryRun = false,
    bool withTests = true,
  }) async {
    if (featureName.isEmpty) {
      throw Exception('Feature name is required.');
    }
    if (!isSnakeCase(featureName)) {
      throw Exception('Feature name must be in snake_case.');
    }

    final featureDir = getNewFeatureDir(featureName);
    if (Directory(featureDir).existsSync() && !force) {
      throw Exception(
        'Feature "$featureName" already exists. Use --force to overwrite.',
      );
    }

    final className = toPascalCase(featureName);

    final testDir = p.join(
      projectDir,
      'test',
      'features',
      featureName,
      'presentation',
      'pages',
    );
    final testPath = p.join(testDir, '${featureName}_page_test.dart');

    if (dryRun) {
      logDryRun('create feature "$featureName"', featureDir);
      if (withTests) {
        logDryRun('create feature page test "$featureName"', testPath);
      }
      await _routerUpdater.addRoute(
        featureName: featureName,
        className: '${className}Page',
        fileName: '${featureName}_page.dart',
        dryRun: true,
      );
      return;
    }

    final variables = <String, String>{
      'feature_name': featureName,
      'class_name': className,
    };

    await copyTemplate(
      templateSubPath: 'feature',
      targetDir: featureDir,
      variables: variables,
    );

    if (withTests) {
      await generateTest(
        testTemplateSubPath: 'feature',
        testDir: testDir,
        variables: {
          'project_name': getProjectName(),
          'feature_name': featureName,
          'class_name': className,
        },
      );
    }

    await _routerUpdater.addRoute(
      featureName: featureName,
      className: '${className}Page',
      fileName: '${featureName}_page.dart',
    );

    logger.success('Feature "$featureName" created successfully.');
  }
}
