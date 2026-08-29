import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';

class ProviderGenerator extends BaseGenerator {
  ProviderGenerator({
    super.templateService,
    super.templatesRootOverride,
    super.workingDirectory,
  });

  Future<void> generate(
    String featureName,
    String providerName, {
    bool force = false,
    bool dryRun = false,
  }) async {
    if (featureName.isEmpty || providerName.isEmpty) {
      throw Exception('Feature name and provider name are required.');
    }
    if (!isSnakeCase(featureName) || !isSnakeCase(providerName)) {
      throw Exception('Names must be in snake_case.');
    }

    final featureDir = getFeatureDir(featureName);
    final providersDir = p.join(featureDir, 'presentation', 'providers');
    final targetPath = p.join(providersDir, '${providerName}_provider.dart');
    checkFileExists(targetPath, 'Provider "$providerName"', force: force);

    if (dryRun) {
      logDryRun('create provider "$providerName"', targetPath);
      return;
    }

    ensureDirectory(providersDir);

    final className = toPascalCase(providerName);
    await copyTemplate(
      templateSubPath: 'provider',
      targetDir: providersDir,
      variables: {'provider_name': providerName, 'class_name': className},
    );

    print('Provider "$providerName" created in feature "$featureName".');
  }
}
