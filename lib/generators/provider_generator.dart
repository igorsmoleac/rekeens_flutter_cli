import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

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
    String? stateManagement,
  }) async {
    if (featureName.isEmpty || providerName.isEmpty) {
      throw Exception('Feature name and provider name are required.');
    }
    if (!isSnakeCase(featureName) || !isSnakeCase(providerName)) {
      throw Exception('Names must be in snake_case.');
    }

    final sm = stateManagement ?? detectStateManagement();
    final useBloc = sm == 'bloc';

    final featureDir = getFeatureDir(featureName);
    final providersDir = p.join(featureDir, 'presentation', 'providers');
    final targetPath = p.join(
      providersDir,
      useBloc ? '${providerName}_cubit.dart' : '${providerName}_provider.dart',
    );
    checkFileExists(
      targetPath,
      useBloc ? 'Cubit "$providerName"' : 'Provider "$providerName"',
      force: force,
    );

    if (dryRun) {
      logDryRun(
        useBloc
            ? 'create cubit "$providerName"'
            : 'create provider "$providerName"',
        targetPath,
      );
      return;
    }

    ensureDirectory(providersDir);

    final className = toPascalCase(providerName);
    await copyTemplate(
      templateSubPath: useBloc ? 'cubit' : 'provider',
      targetDir: providersDir,
      variables: {'provider_name': providerName, 'class_name': className},
    );

    logger.success(
      useBloc
          ? 'Cubit "$providerName" created in feature "$featureName".'
          : 'Provider "$providerName" created in feature "$featureName".',
    );
  }
}
