import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

class DatasourceGenerator extends BaseGenerator {
  DatasourceGenerator({
    super.templateService,
    super.templatesRootOverride,
    super.workingDirectory,
  });

  /// Placeholder used when no `baseUrl` is provided. Users are expected to
  /// replace it with their real API endpoint (e.g. via `--base-url` or
  /// `rekeens.yaml`).
  static const _defaultBaseUrl = 'https://api.example.com';

  Future<void> generate(
    String featureName,
    String datasourceName, {
    String? baseUrl,
    bool force = false,
    bool dryRun = false,
    bool withTests = true,
  }) async {
    if (featureName.isEmpty || datasourceName.isEmpty) {
      throw Exception('Feature name and datasource name are required.');
    }
    if (!isSnakeCase(featureName) || !isSnakeCase(datasourceName)) {
      throw Exception('Names must be in snake_case.');
    }

    final featureDir = getFeatureDir(featureName);
    final datasourcesDir = p.join(featureDir, 'data', 'datasources');
    final interfacePath = p.join(
      datasourcesDir,
      '${datasourceName}_datasource.dart',
    );
    final implPath = p.join(
      datasourcesDir,
      '${datasourceName}_datasource_impl.dart',
    );
    checkFileExists(
      interfacePath,
      'Datasource interface "$datasourceName"',
      force: force,
    );
    checkFileExists(
      implPath,
      'Datasource implementation "$datasourceName"',
      force: force,
    );

    final testDir = p.join(
      projectDir,
      'test',
      'features',
      featureName,
      'data',
      'datasources',
    );
    final testPath = p.join(testDir, '${datasourceName}_datasource_test.dart');

    if (dryRun) {
      logDryRun('create datasource interface "$datasourceName"', interfacePath);
      logDryRun('create datasource implementation "$datasourceName"', implPath);
      if (withTests) {
        logDryRun('create datasource test "$datasourceName"', testPath);
      }
      return;
    }

    ensureDirectory(datasourcesDir);

    final className = toPascalCase(datasourceName);
    final effectiveBaseUrl = baseUrl ?? _defaultBaseUrl;
    final variables = <String, String>{
      'datasource_name': datasourceName,
      'class_name': className,
      'base_url': effectiveBaseUrl,
    };

    await copyTemplate(
      templateSubPath: 'datasource',
      targetDir: datasourcesDir,
      variables: variables,
    );

    if (withTests) {
      await generateTest(
        testTemplateSubPath: 'datasource',
        testDir: testDir,
        variables: {
          'project_name': getProjectName(),
          'feature_name': featureName,
          'datasource_name': datasourceName,
          'class_name': className,
        },
      );
    }

    logger.success(
      'Datasource "$datasourceName" created in feature "$featureName".',
    );
  }
}
