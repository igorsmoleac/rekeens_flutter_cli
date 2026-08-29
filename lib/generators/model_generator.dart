import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';

class ModelGenerator extends BaseGenerator {
  ModelGenerator({
    super.templateService,
    super.templatesRootOverride,
    super.workingDirectory,
  });

  Future<void> generate(
    String featureName,
    String modelName, {
    bool force = false,
  }) async {
    if (featureName.isEmpty || modelName.isEmpty) {
      throw Exception('Feature name and model name are required.');
    }
    if (!isSnakeCase(featureName) || !isSnakeCase(modelName)) {
      throw Exception('Names must be in snake_case.');
    }

    final featureDir = getFeatureDir(featureName);
    final modelsDir = p.join(featureDir, 'data', 'models');
    final targetPath = p.join(modelsDir, '${modelName}_model.dart');
    checkFileExists(targetPath, 'Model "$modelName"', force: force);

    ensureDirectory(modelsDir);

    final className = toPascalCase(modelName);
    await copyTemplate(
      templateSubPath: 'model',
      targetDir: modelsDir,
      variables: {'model_name': modelName, 'class_name': className},
    );

    print('Model "$modelName" created in feature "$featureName".');
  }
}
