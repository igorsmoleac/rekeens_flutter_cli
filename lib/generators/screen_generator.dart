import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';
import 'package:rekeens_flutter_cli/services/router_updater.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

class ScreenGenerator extends BaseGenerator {
  ScreenGenerator({
    super.templateService,
    super.templatesRootOverride,
    super.workingDirectory,
    RouterUpdater? routerUpdater,
  }) : _routerUpdater =
           routerUpdater ?? RouterUpdater(workingDirectory: workingDirectory);

  final RouterUpdater _routerUpdater;

  Future<void> generate(
    String featureName,
    String screenName, {
    bool force = false,
    bool dryRun = false,
    bool withTests = true,
  }) async {
    if (featureName.isEmpty || screenName.isEmpty) {
      throw Exception('Feature name and screen name are required.');
    }
    if (!isSnakeCase(featureName) || !isSnakeCase(screenName)) {
      throw Exception('Names must be in snake_case.');
    }

    final featureDir = getFeatureDir(featureName);
    final pagesDir = p.join(featureDir, 'presentation', 'pages');
    final targetPath = p.join(pagesDir, '${screenName}_screen.dart');
    checkFileExists(targetPath, 'Screen "$screenName"', force: force);

    final testDir = p.join(
      projectDir,
      'test',
      'features',
      featureName,
      'presentation',
      'pages',
    );
    final testPath = p.join(testDir, '${screenName}_screen_test.dart');

    final className = toPascalCase(screenName);

    if (dryRun) {
      logDryRun('create screen "$screenName"', targetPath);
      if (withTests) logDryRun('create screen test "$screenName"', testPath);
      await _routerUpdater.addRoute(
        featureName: featureName,
        screenName: screenName,
        className: '${className}Screen',
        fileName: '${screenName}_screen.dart',
        dryRun: true,
      );
      return;
    }

    ensureDirectory(pagesDir);

    await copyTemplate(
      templateSubPath: 'screen',
      targetDir: pagesDir,
      variables: {'screen_name': screenName, 'class_name': className},
    );

    if (withTests) {
      await generateTest(
        testTemplateSubPath: 'screen',
        testDir: testDir,
        variables: {
          'project_name': getProjectName(),
          'feature_name': featureName,
          'screen_name': screenName,
          'class_name': className,
        },
      );
    }

    await _routerUpdater.addRoute(
      featureName: featureName,
      screenName: screenName,
      className: '${className}Screen',
      fileName: '${screenName}_screen.dart',
    );

    logger.success('Screen "$screenName" created in feature "$featureName".');
  }
}
