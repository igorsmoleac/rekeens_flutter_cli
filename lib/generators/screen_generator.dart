import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';

class ScreenGenerator extends BaseGenerator {
  ScreenGenerator({
    super.templateService,
    super.templatesRootOverride,
    super.workingDirectory,
  });

  Future<void> generate(
    String featureName,
    String screenName, {
    bool force = false,
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

    ensureDirectory(pagesDir);

    final className = toPascalCase(screenName);
    await copyTemplate(
      templateSubPath: 'screen',
      targetDir: pagesDir,
      variables: {'screen_name': screenName, 'class_name': className},
    );

    print('Screen "$screenName" created in feature "$featureName".');
  }
}
