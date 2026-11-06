import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/datasource_generator.dart';
import 'package:rekeens_flutter_cli/generators/entity_generator.dart';
import 'package:rekeens_flutter_cli/generators/feature_generator.dart';
import 'package:rekeens_flutter_cli/generators/model_generator.dart';
import 'package:rekeens_flutter_cli/generators/provider_generator.dart';
import 'package:rekeens_flutter_cli/generators/repository_generator.dart';
import 'package:rekeens_flutter_cli/generators/screen_generator.dart';
import 'package:rekeens_flutter_cli/generators/service_generator.dart';
import 'package:rekeens_flutter_cli/generators/test_generator.dart';
import 'package:rekeens_flutter_cli/generators/usecase_generator.dart';
import 'package:test/test.dart';

import 'helpers/generator_test_helper.dart';

/// One row of the "every component type" matrix: how to create the component
/// (without its test stub), where the generated test is expected, and a
/// content marker proving the right template was rendered.
class _ComponentCase {
  const _ComponentCase(
    this.type,
    this.createComponent,
    this.featureName,
    this.componentName,
    this.testSegments,
    this.marker,
  );

  final String type;
  final Future<void> Function(GeneratorTestHelper h) createComponent;
  final String featureName;
  final String componentName;
  final List<String> testSegments;
  final String marker;

  String get description =>
      'creates a $type test for "$componentName" in feature "$featureName"';
}

void main() {
  final h = GeneratorTestHelper()..register();

  TestGenerator testGenerator() => TestGenerator(
    workingDirectory: h.tempProject.path,
    templatesRootOverride: h.projectRoot,
  );

  final cases = <_ComponentCase>[
    _ComponentCase(
      'model',
      (h) => ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      ).generate('auth', 'user', withTests: false),
      'auth',
      'user',
      ['data', 'models', 'user_model_test.dart'],
      "group('UserModel'",
    ),
    _ComponentCase(
      'repository',
      (h) => RepositoryGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      ).generate('auth', 'user', withTests: false),
      'auth',
      'user',
      ['data', 'repositories', 'user_repository_test.dart'],
      '_FakeUserRepository',
    ),
    _ComponentCase(
      'screen',
      (h) => ScreenGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      ).generate('auth', 'login', withTests: false),
      'auth',
      'login',
      ['presentation', 'pages', 'login_screen_test.dart'],
      "group('LoginScreen'",
    ),
    _ComponentCase(
      'service',
      (h) => ServiceGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      ).generate('auth', 'api', withTests: false),
      'auth',
      'api',
      ['data', 'services', 'api_service_test.dart'],
      "group('ApiService'",
    ),
    _ComponentCase(
      'provider',
      (h) => ProviderGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      ).generate('auth', 'session', withTests: false),
      'auth',
      'session',
      ['presentation', 'providers', 'session_provider_test.dart'],
      "group('sessionProvider'",
    ),
    _ComponentCase(
      'cubit',
      (h) => ProviderGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      ).generate('auth', 'counter', stateManagement: 'bloc', withTests: false),
      'auth',
      'counter',
      ['presentation', 'providers', 'counter_cubit_test.dart'],
      "group('CounterCubit'",
    ),
    _ComponentCase(
      'entity',
      (h) => EntityGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      ).generate('auth', 'user', withTests: false),
      'auth',
      'user',
      ['domain', 'entities', 'user_entity_test.dart'],
      "group('UserEntity'",
    ),
    _ComponentCase(
      'usecase',
      (h) => UseCaseGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      ).generate('auth', 'login', withTests: false),
      'auth',
      'login',
      ['domain', 'usecases', 'login_usecase_test.dart'],
      "group('LoginUseCase'",
    ),
    _ComponentCase(
      'datasource',
      (h) => DatasourceGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      ).generate('auth', 'user_api', withTests: false),
      'auth',
      'user_api',
      ['data', 'datasources', 'user_api_datasource_test.dart'],
      '_FakeHttpClient',
    ),
    _ComponentCase(
      'feature',
      (h) => FeatureGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      ).generate('shop', withTests: false),
      'shop',
      'shop',
      ['presentation', 'pages', 'shop_page_test.dart'],
      "group('ShopPage'",
    ),
  ];

  group('TestGenerator', () {
    group('creates a test for every component type', () {
      for (final c in cases) {
        test(c.description, () async {
          // The feature case creates its own feature; every other component
          // needs an existing feature to live in.
          if (c.type == 'feature') {
            await c.createComponent(h);
          } else {
            await h.withAuthFeature(() => c.createComponent(h));
          }
          await testGenerator().generate(
            c.type,
            c.featureName,
            c.componentName,
          );

          final testFile = File(
            p.joinAll([
              h.tempProject.path,
              'test',
              'features',
              c.featureName,
              ...c.testSegments,
            ]),
          );
          expect(testFile.existsSync(), isTrue, reason: c.marker);
          expect(testFile.readAsStringSync(), contains(c.marker));
        });
      }
    });

    group('validation', () {
      test('throws when the component does not exist', () async {
        await h.withAuthFeature(() async {
          await expectLater(
            testGenerator().generate('model', 'auth', 'missing'),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Component file not found'),
              ),
            ),
          );
        });
      });

      test('throws when the feature does not exist', () async {
        await expectLater(
          testGenerator().generate('model', 'nope', 'user'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('does not exist'),
            ),
          ),
        );
      });

      test('throws for an unknown component type', () async {
        await h.withAuthFeature(() async {
          await expectLater(
            testGenerator().generate('widget', 'auth', 'fancy'),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Unknown component type'),
              ),
            ),
          );
        });
      });

      test('throws when the test already exists', () async {
        await h.withAuthFeature(() async {
          await ModelGenerator(
            workingDirectory: h.tempProject.path,
            templatesRootOverride: h.projectRoot,
          ).generate('auth', 'user');

          await expectLater(
            testGenerator().generate('model', 'auth', 'user'),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('already exists'),
              ),
            ),
          );
        });
      });
    });

    group('flags', () {
      test('force=true overwrites an existing test', () async {
        await h.withAuthFeature(() async {
          await ModelGenerator(
            workingDirectory: h.tempProject.path,
            templatesRootOverride: h.projectRoot,
          ).generate('auth', 'user');

          final testFile = File(
            p.join(
              h.tempProject.path,
              'test',
              'features',
              'auth',
              'data',
              'models',
              'user_model_test.dart',
            ),
          );
          testFile.writeAsStringSync('// stale content');
          expect(testFile.existsSync(), isTrue);

          await testGenerator().generate('model', 'auth', 'user', force: true);

          expect(testFile.existsSync(), isTrue);
          expect(testFile.readAsStringSync(), contains("group('UserModel'"));
        });
      });

      test('dry-run prints the plan without writing any files', () async {
        await h.withAuthFeature(() async {
          await ModelGenerator(
            workingDirectory: h.tempProject.path,
            templatesRootOverride: h.projectRoot,
          ).generate('auth', 'user', withTests: false);

          await testGenerator().generate('model', 'auth', 'user', dryRun: true);

          final testFile = File(
            p.join(
              h.tempProject.path,
              'test',
              'features',
              'auth',
              'data',
              'models',
              'user_model_test.dart',
            ),
          );
          expect(testFile.existsSync(), isFalse);
        });
      });
    });
  });
}
