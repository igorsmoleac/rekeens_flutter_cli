import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

/// Per-component rules for the standalone test generator: which files make up
/// the component, where its test stub lives, and which template renders it.
class _ComponentSpec {
  const _ComponentSpec({
    required this.componentFiles,
    required this.testSubDir,
    required this.testSuffix,
    required this.templateSubPath,
    required this.nameVariable,
  });

  /// Component files the generated test imports, relative to
  /// `lib/features/<feature>/`. `{name}` is replaced with the component name.
  final List<String> componentFiles;

  /// Test directory relative to `test/features/<feature>/` (mirrors lib/).
  final String testSubDir;

  /// Suffix appended to the component name to build the test file name.
  final String testSuffix;

  /// Subdirectory under `templates/tests/`.
  final String templateSubPath;

  /// Placeholder key carrying the component name inside the test template.
  final String nameVariable;
}

/// Generates only the test stub for an already existing component:
/// `rekeens generate test <type> <feature_name> <component_name>`.
class TestGenerator extends BaseGenerator {
  TestGenerator({
    super.templateService,
    super.templatesRootOverride,
    super.workingDirectory,
  });

  static const _specs = <String, _ComponentSpec>{
    'model': _ComponentSpec(
      componentFiles: ['data/models/{name}_model.dart'],
      testSubDir: 'data/models',
      testSuffix: '_model_test.dart',
      templateSubPath: 'model',
      nameVariable: 'model_name',
    ),
    'repository': _ComponentSpec(
      componentFiles: [
        'domain/repositories/{name}_repository.dart',
        'data/repositories/{name}_repository_impl.dart',
      ],
      testSubDir: 'data/repositories',
      testSuffix: '_repository_test.dart',
      templateSubPath: 'repository',
      nameVariable: 'repository_name',
    ),
    'screen': _ComponentSpec(
      componentFiles: ['presentation/pages/{name}_screen.dart'],
      testSubDir: 'presentation/pages',
      testSuffix: '_screen_test.dart',
      templateSubPath: 'screen',
      nameVariable: 'screen_name',
    ),
    'service': _ComponentSpec(
      componentFiles: ['data/services/{name}_service.dart'],
      testSubDir: 'data/services',
      testSuffix: '_service_test.dart',
      templateSubPath: 'service',
      nameVariable: 'service_name',
    ),
    'entity': _ComponentSpec(
      componentFiles: ['domain/entities/{name}_entity.dart'],
      testSubDir: 'domain/entities',
      testSuffix: '_entity_test.dart',
      templateSubPath: 'entity',
      nameVariable: 'entity_name',
    ),
    'usecase': _ComponentSpec(
      componentFiles: ['domain/usecases/{name}_usecase.dart'],
      testSubDir: 'domain/usecases',
      testSuffix: '_usecase_test.dart',
      templateSubPath: 'usecase',
      nameVariable: 'usecase_name',
    ),
    'provider': _ComponentSpec(
      componentFiles: [
        'presentation/providers/{name}_provider.dart',
        'presentation/providers/{name}_state.dart',
      ],
      testSubDir: 'presentation/providers',
      testSuffix: '_provider_test.dart',
      templateSubPath: 'provider',
      nameVariable: 'provider_name',
    ),
    'cubit': _ComponentSpec(
      componentFiles: [
        'presentation/providers/{name}_cubit.dart',
        'presentation/providers/{name}_state.dart',
      ],
      testSubDir: 'presentation/providers',
      testSuffix: '_cubit_test.dart',
      templateSubPath: 'cubit',
      nameVariable: 'provider_name',
    ),
    'datasource': _ComponentSpec(
      componentFiles: [
        'data/datasources/{name}_datasource.dart',
        'data/datasources/{name}_datasource_impl.dart',
      ],
      testSubDir: 'data/datasources',
      testSuffix: '_datasource_test.dart',
      templateSubPath: 'datasource',
      nameVariable: 'datasource_name',
    ),
    'feature': _ComponentSpec(
      componentFiles: ['presentation/pages/{name}_page.dart'],
      testSubDir: 'presentation/pages',
      testSuffix: '_page_test.dart',
      templateSubPath: 'feature',
      nameVariable: 'feature_name',
    ),
  };

  Future<void> generate(
    String componentType,
    String featureName,
    String componentName, {
    bool force = false,
    bool dryRun = false,
  }) async {
    if (featureName.isEmpty || componentName.isEmpty) {
      throw Exception('Feature name and component name are required.');
    }
    if (!isSnakeCase(featureName) || !isSnakeCase(componentName)) {
      throw Exception('Names must be in snake_case.');
    }

    final spec = _specs[componentType];
    if (spec == null) {
      throw Exception(
        'Unknown component type "$componentType" for test generation. '
        'Supported: ${_specs.keys.join(', ')}',
      );
    }
    if (componentType == 'feature' && componentName != featureName) {
      throw Exception(
        'Feature tests are named after the feature. '
        'Use: rekeens g test feature $featureName $featureName',
      );
    }

    final featureDir = getFeatureDir(featureName);
    for (final template in spec.componentFiles) {
      final relativePath = template.replaceAll('{name}', componentName);
      final componentFile = File(p.join(featureDir, relativePath));
      if (!componentFile.existsSync()) {
        throw Exception(
          'Component file not found at ${componentFile.path}. '
          'Generate it first with: '
          'rekeens g $componentType $featureName $componentName',
        );
      }
    }

    final testDir = p.joinAll([
      projectDir,
      'test',
      'features',
      featureName,
      ...spec.testSubDir.split('/'),
    ]);
    final testPath = p.join(testDir, '$componentName${spec.testSuffix}');
    checkFileExists(testPath, 'Test "$componentName"', force: force);

    if (dryRun) {
      logDryRun('create $componentType test "$componentName"', testPath);
      return;
    }

    await generateTest(
      testTemplateSubPath: spec.templateSubPath,
      testDir: testDir,
      variables: {
        'project_name': getProjectName(),
        'feature_name': featureName,
        spec.nameVariable: componentName,
        'class_name': toPascalCase(componentName),
      },
    );

    final message = componentType == 'feature'
        ? 'Test for feature "$featureName" created.'
        : 'Test for $componentType "$componentName" created in feature '
              '"$featureName".';
    logger.success(message);
  }
}
