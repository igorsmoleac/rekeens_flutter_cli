import 'dart:io';

import 'package:rekeens_flutter_cli/generators/base_generator.dart';

class FeatureGenerator extends BaseGenerator {
  FeatureGenerator({
    super.templateService,
    super.templatesRootOverride,
    super.workingDirectory,
  });

  Future<void> generate(String featureName, {bool force = false}) async {
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
    final variables = <String, String>{
      'feature_name': featureName,
      'class_name': className,
    };

    await copyTemplate(
      templateSubPath: 'feature',
      targetDir: featureDir,
      variables: variables,
    );

    print('Feature "$featureName" created successfully.');
  }
}
