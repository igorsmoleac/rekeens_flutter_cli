import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/datasource_generator.dart';
import 'package:rekeens_flutter_cli/generators/entity_generator.dart';
import 'package:rekeens_flutter_cli/generators/provider_generator.dart';
import 'package:rekeens_flutter_cli/generators/repository_generator.dart';
import 'package:rekeens_flutter_cli/generators/service_generator.dart';
import 'package:rekeens_flutter_cli/generators/usecase_generator.dart';
import 'package:test/test.dart';

import 'helpers/generator_test_helper.dart';

void main() {
  final h = GeneratorTestHelper()..register();

  group('RepositoryGenerator', () {
    test('creates interface in domain/ and impl in data/', () async {
      await h.withAuthFeature(() async {
        final gen = RepositoryGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user');

        final interfaceFile = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'domain',
            'repositories',
            'user_repository.dart',
          ),
        );
        expect(interfaceFile.existsSync(), isTrue);
        final interfaceContent = interfaceFile.readAsStringSync();
        expect(
          interfaceContent.contains('abstract class UserRepository'),
          isTrue,
        );

        final implFile = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'data',
            'repositories',
            'user_repository_impl.dart',
          ),
        );
        expect(implFile.existsSync(), isTrue);
        final implContent = implFile.readAsStringSync();
        expect(implContent.contains('class UserRepositoryImpl'), isTrue);
        expect(
          implContent.contains(
            "import '../../domain/repositories/user_repository.dart';",
          ),
          isTrue,
        );
      });
    });

    test('throws when file exists and force=false', () async {
      await h.withAuthFeature(() async {
        final gen = RepositoryGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user');

        expect(() => gen.generate('auth', 'user'), throwsA(isA<Exception>()));
      });
    });

    test('overwrites when file exists and force=true', () async {
      await h.withAuthFeature(() async {
        final gen = RepositoryGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user');

        await gen.generate('auth', 'user', force: true);

        final interfaceFile = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'domain',
            'repositories',
            'user_repository.dart',
          ),
        );
        expect(interfaceFile.existsSync(), isTrue);
        expect(
          interfaceFile.readAsStringSync().contains(
            'abstract class UserRepository',
          ),
          isTrue,
        );

        final implFile = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'data',
            'repositories',
            'user_repository_impl.dart',
          ),
        );
        expect(implFile.existsSync(), isTrue);
        expect(
          implFile.readAsStringSync().contains('class UserRepositoryImpl'),
          isTrue,
        );
      });
    });

    test('throws on invalid name (UserProfile)', () async {
      await h.withAuthFeature(() async {
        final gen = RepositoryGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        expect(
          () => gen.generate('auth', 'UserProfile'),
          throwsA(isA<Exception>()),
        );
      });
    });

    test('throws when feature does not exist', () {
      final gen = RepositoryGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      expect(() => gen.generate('missing', 'user'), throwsA(isA<Exception>()));
    });
  });

  group('ServiceGenerator', () {
    test('creates auth_service.dart with AuthService class', () async {
      await h.withAuthFeature(() async {
        final gen = ServiceGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'auth');

        final file = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'data',
            'services',
            'auth_service.dart',
          ),
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content.contains('class AuthService'), isTrue);
      });
    });

    test('throws when file exists and force=false', () async {
      await h.withAuthFeature(() async {
        final gen = ServiceGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'auth');

        expect(() => gen.generate('auth', 'auth'), throwsA(isA<Exception>()));
      });
    });

    test('overwrites when file exists and force=true', () async {
      await h.withAuthFeature(() async {
        final gen = ServiceGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'auth');

        await gen.generate('auth', 'auth', force: true);

        final file = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'data',
            'services',
            'auth_service.dart',
          ),
        );
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync().contains('class AuthService'), isTrue);
      });
    });

    test('throws on invalid name (UserProfile)', () async {
      await h.withAuthFeature(() async {
        final gen = ServiceGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        expect(
          () => gen.generate('auth', 'UserProfile'),
          throwsA(isA<Exception>()),
        );
      });
    });

    test('throws when feature does not exist', () {
      final gen = ServiceGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      expect(() => gen.generate('missing', 'auth'), throwsA(isA<Exception>()));
    });
  });

  group('EntityGenerator', () {
    test('creates user_entity.dart in domain/entities', () async {
      await h.withAuthFeature(() async {
        final gen = EntityGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user');

        final file = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'domain',
            'entities',
            'user_entity.dart',
          ),
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content.contains('class UserEntity'), isTrue);
      });
    });

    test('throws when file exists and force=false', () async {
      await h.withAuthFeature(() async {
        final gen = EntityGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user');

        expect(() => gen.generate('auth', 'user'), throwsA(isA<Exception>()));
      });
    });

    test('overwrites when file exists and force=true', () async {
      await h.withAuthFeature(() async {
        final gen = EntityGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user');

        await gen.generate('auth', 'user', force: true);

        final file = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'domain',
            'entities',
            'user_entity.dart',
          ),
        );
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync().contains('class UserEntity'), isTrue);
      });
    });

    test('throws on invalid name (UserProfile)', () async {
      await h.withAuthFeature(() async {
        final gen = EntityGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        expect(
          () => gen.generate('auth', 'UserProfile'),
          throwsA(isA<Exception>()),
        );
      });
    });

    test('throws when feature does not exist', () {
      final gen = EntityGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      expect(() => gen.generate('missing', 'user'), throwsA(isA<Exception>()));
    });
  });

  group('UseCaseGenerator', () {
    test('creates login_usecase.dart in domain/usecases', () async {
      await h.withAuthFeature(() async {
        final gen = UseCaseGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'login');

        final file = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'domain',
            'usecases',
            'login_usecase.dart',
          ),
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content.contains('class LoginUseCase'), isTrue);
        expect(content.contains('class LoginParams'), isTrue);
      });
    });

    test('throws when file exists and force=false', () async {
      await h.withAuthFeature(() async {
        final gen = UseCaseGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'login');

        expect(() => gen.generate('auth', 'login'), throwsA(isA<Exception>()));
      });
    });

    test('overwrites when file exists and force=true', () async {
      await h.withAuthFeature(() async {
        final gen = UseCaseGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'login');

        await gen.generate('auth', 'login', force: true);

        final file = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'domain',
            'usecases',
            'login_usecase.dart',
          ),
        );
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync().contains('class LoginUseCase'), isTrue);
      });
    });

    test('throws on invalid name (LoginUser)', () async {
      await h.withAuthFeature(() async {
        final gen = UseCaseGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        expect(
          () => gen.generate('auth', 'LoginUser'),
          throwsA(isA<Exception>()),
        );
      });
    });

    test('throws when feature does not exist', () {
      final gen = UseCaseGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      expect(() => gen.generate('missing', 'login'), throwsA(isA<Exception>()));
    });
  });

  group('DatasourceGenerator', () {
    test('creates interface and impl in data/datasources', () async {
      await h.withAuthFeature(() async {
        final gen = DatasourceGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user_api');

        final interfaceFile = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'data',
            'datasources',
            'user_api_datasource.dart',
          ),
        );
        expect(interfaceFile.existsSync(), isTrue);
        final interfaceContent = interfaceFile.readAsStringSync();
        expect(
          interfaceContent.contains('abstract class UserApiDataSource'),
          isTrue,
        );
        expect(interfaceContent.contains('fetchData'), isTrue);
        expect(interfaceContent.contains('postData'), isTrue);

        final implFile = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'data',
            'datasources',
            'user_api_datasource_impl.dart',
          ),
        );
        expect(implFile.existsSync(), isTrue);
        final implContent = implFile.readAsStringSync();
        expect(implContent.contains('class UserApiDataSourceImpl'), isTrue);
        expect(
          implContent.contains("import 'user_api_datasource.dart';"),
          isTrue,
        );
        expect(implContent.contains('HttpClient'), isTrue);
      });
    });

    test('throws when file exists and force=false', () async {
      await h.withAuthFeature(() async {
        final gen = DatasourceGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user_api');

        expect(
          () => gen.generate('auth', 'user_api'),
          throwsA(isA<Exception>()),
        );
      });
    });

    test('overwrites when file exists and force=true', () async {
      await h.withAuthFeature(() async {
        final gen = DatasourceGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user_api');

        await gen.generate('auth', 'user_api', force: true);

        final implFile = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'data',
            'datasources',
            'user_api_datasource_impl.dart',
          ),
        );
        expect(implFile.existsSync(), isTrue);
        expect(
          implFile.readAsStringSync().contains('UserApiDataSourceImpl'),
          isTrue,
        );
      });
    });

    test('throws on invalid name (UserApi)', () async {
      await h.withAuthFeature(() async {
        final gen = DatasourceGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        expect(
          () => gen.generate('auth', 'UserApi'),
          throwsA(isA<Exception>()),
        );
      });
    });

    test('throws when feature does not exist', () {
      final gen = DatasourceGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      expect(
        () => gen.generate('missing', 'user_api'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('DatasourceGenerator — tests', () {
    test('creates test file by default', () async {
      await h.withAuthFeature(() async {
        final gen = DatasourceGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user_api');

        final testFile = File(
          p.join(
            h.tempProject.path,
            'test',
            'features',
            'auth',
            'data',
            'datasources',
            'user_api_datasource_test.dart',
          ),
        );
        expect(testFile.existsSync(), isTrue);
        final content = testFile.readAsStringSync();
        expect(content.contains('UserApiDataSource'), isTrue);
        expect(content.contains('fetchData'), isTrue);
        expect(content.contains('postData'), isTrue);
      });
    });

    test('skips test file when withTests=false', () async {
      await h.withAuthFeature(() async {
        final gen = DatasourceGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user_api', withTests: false);

        final testFile = File(
          p.join(
            h.tempProject.path,
            'test',
            'features',
            'auth',
            'data',
            'datasources',
            'user_api_datasource_test.dart',
          ),
        );
        expect(testFile.existsSync(), isFalse);
      });
    });
  });

  group('ProviderGenerator', () {
    test(
      'creates auth_provider.dart with AuthNotifier and authProvider + state',
      () async {
        await h.withAuthFeature(() async {
          final gen = ProviderGenerator(
            workingDirectory: h.tempProject.path,
            templatesRootOverride: h.projectRoot,
          );
          await gen.generate('auth', 'auth');

          final file = File(
            p.join(
              h.tempProject.path,
              'lib',
              'features',
              'auth',
              'presentation',
              'providers',
              'auth_provider.dart',
            ),
          );
          expect(file.existsSync(), isTrue);
          final content = file.readAsStringSync();
          expect(content.contains('class AuthNotifier'), isTrue);
          expect(content.contains('authProvider'), isTrue);
          expect(content.contains('StateNotifierProvider'), isTrue);
          expect(content.contains('StateNotifier'), isTrue);

          final stateFile = File(
            p.join(
              h.tempProject.path,
              'lib',
              'features',
              'auth',
              'presentation',
              'providers',
              'auth_state.dart',
            ),
          );
          expect(stateFile.existsSync(), isTrue);
          expect(
            stateFile.readAsStringSync().contains('class AuthState'),
            isTrue,
          );
        });
      },
    );

    test('throws when file exists and force=false', () async {
      await h.withAuthFeature(() async {
        final gen = ProviderGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'auth');

        expect(() => gen.generate('auth', 'auth'), throwsA(isA<Exception>()));
      });
    });

    test('overwrites when file exists and force=true', () async {
      await h.withAuthFeature(() async {
        final gen = ProviderGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'auth');

        await gen.generate('auth', 'auth', force: true);

        final file = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'presentation',
            'providers',
            'auth_provider.dart',
          ),
        );
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync().contains('class AuthNotifier'), isTrue);
      });
    });

    test('throws on invalid name (UserProfile)', () async {
      await h.withAuthFeature(() async {
        final gen = ProviderGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        expect(
          () => gen.generate('auth', 'UserProfile'),
          throwsA(isA<Exception>()),
        );
      });
    });

    test('throws when feature does not exist', () {
      final gen = ProviderGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      expect(() => gen.generate('missing', 'auth'), throwsA(isA<Exception>()));
    });
  });

  group('ProviderGenerator (bloc)', () {
    test(
      'creates auth_cubit.dart and auth_state.dart when stateManagement=bloc',
      () async {
        await h.withAuthFeature(() async {
          final gen = ProviderGenerator(
            workingDirectory: h.tempProject.path,
            templatesRootOverride: h.projectRoot,
          );
          await gen.generate('auth', 'auth', stateManagement: 'bloc');

          final cubitFile = File(
            p.join(
              h.tempProject.path,
              'lib',
              'features',
              'auth',
              'presentation',
              'providers',
              'auth_cubit.dart',
            ),
          );
          final stateFile = File(
            p.join(
              h.tempProject.path,
              'lib',
              'features',
              'auth',
              'presentation',
              'providers',
              'auth_state.dart',
            ),
          );
          expect(cubitFile.existsSync(), isTrue);
          expect(stateFile.existsSync(), isTrue);
          final cubitContent = cubitFile.readAsStringSync();
          expect(cubitContent.contains('class AuthCubit'), isTrue);
          expect(cubitContent.contains('import \'auth_state.dart\''), isTrue);
          final stateContent = stateFile.readAsStringSync();
          expect(stateContent.contains('sealed class AuthState'), isTrue);
          expect(stateContent.contains('class AuthInitial'), isTrue);
        });
      },
    );

    test('auto-detects bloc from pubspec.yaml', () async {
      await h.withAuthFeature(() async {
        File(p.join(h.tempProject.path, 'pubspec.yaml')).writeAsStringSync(
          'name: test\n'
          'dependencies:\n'
          '  flutter_bloc: ^8.1.0\n',
        );

        final gen = ProviderGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'auth');

        final cubitFile = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'presentation',
            'providers',
            'auth_cubit.dart',
          ),
        );
        expect(cubitFile.existsSync(), isTrue);
        expect(
          cubitFile.readAsStringSync().contains('class AuthCubit'),
          isTrue,
        );
      });
    });

    test('auto-detects riverpod from pubspec.yaml', () async {
      await h.withAuthFeature(() async {
        File(p.join(h.tempProject.path, 'pubspec.yaml')).writeAsStringSync(
          'name: test\n'
          'dependencies:\n'
          '  flutter_riverpod: ^2.4.0\n',
        );

        final gen = ProviderGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'auth');

        final providerFile = File(
          p.join(
            h.tempProject.path,
            'lib',
            'features',
            'auth',
            'presentation',
            'providers',
            'auth_provider.dart',
          ),
        );
        expect(providerFile.existsSync(), isTrue);
        expect(
          providerFile.readAsStringSync().contains('class AuthNotifier'),
          isTrue,
        );
      });
    });
  });

  // --- Test generation ---

  group('RepositoryGenerator — tests', () {
    test('creates test file by default', () async {
      await h.withAuthFeature(() async {
        final gen = RepositoryGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user');

        final testFile = File(
          p.join(
            h.tempProject.path,
            'test',
            'features',
            'auth',
            'data',
            'repositories',
            'user_repository_test.dart',
          ),
        );
        expect(testFile.existsSync(), isTrue);
        final content = testFile.readAsStringSync();
        expect(content.contains('UserRepository'), isTrue);
        expect(content.contains('getItems'), isTrue);
        expect(
          content.contains('domain/repositories/user_repository.dart'),
          isTrue,
        );
        expect(content.contains('implements UserRepository'), isTrue);
      });
    });

    test('skips test file when withTests=false', () async {
      await h.withAuthFeature(() async {
        final gen = RepositoryGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user', withTests: false);

        final testFile = File(
          p.join(
            h.tempProject.path,
            'test',
            'features',
            'auth',
            'data',
            'repositories',
            'user_repository_test.dart',
          ),
        );
        expect(testFile.existsSync(), isFalse);
      });
    });
  });

  group('ServiceGenerator — tests', () {
    test('creates test file by default', () async {
      await h.withAuthFeature(() async {
        final gen = ServiceGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'auth');

        final testFile = File(
          p.join(
            h.tempProject.path,
            'test',
            'features',
            'auth',
            'data',
            'services',
            'auth_service_test.dart',
          ),
        );
        expect(testFile.existsSync(), isTrue);
        final content = testFile.readAsStringSync();
        expect(content.contains('AuthService'), isTrue);
        expect(content.contains('performAction'), isTrue);
      });
    });

    test('skips test file when withTests=false', () async {
      await h.withAuthFeature(() async {
        final gen = ServiceGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'auth', withTests: false);

        final testFile = File(
          p.join(
            h.tempProject.path,
            'test',
            'features',
            'auth',
            'data',
            'services',
            'auth_service_test.dart',
          ),
        );
        expect(testFile.existsSync(), isFalse);
      });
    });
  });

  group('ProviderGenerator — tests', () {
    test('creates provider test file by default (riverpod)', () async {
      await h.withAuthFeature(() async {
        File(p.join(h.tempProject.path, 'pubspec.yaml')).writeAsStringSync(
          'name: test\n'
          'dependencies:\n'
          '  flutter_riverpod: ^2.4.0\n',
        );

        final gen = ProviderGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'auth');

        final testFile = File(
          p.join(
            h.tempProject.path,
            'test',
            'features',
            'auth',
            'presentation',
            'providers',
            'auth_provider_test.dart',
          ),
        );
        expect(testFile.existsSync(), isTrue);
        final content = testFile.readAsStringSync();
        expect(content.contains('authProvider'), isTrue);
        expect(content.contains('ProviderContainer'), isTrue);
        expect(content.contains('count'), isTrue);
        expect(content.contains('isLoading'), isTrue);
      });
    });

    test('creates cubit test file by default (bloc)', () async {
      await h.withAuthFeature(() async {
        File(p.join(h.tempProject.path, 'pubspec.yaml')).writeAsStringSync(
          'name: test\n'
          'dependencies:\n'
          '  flutter_bloc: ^8.1.0\n',
        );

        final gen = ProviderGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'auth');

        final testFile = File(
          p.join(
            h.tempProject.path,
            'test',
            'features',
            'auth',
            'presentation',
            'providers',
            'auth_cubit_test.dart',
          ),
        );
        expect(testFile.existsSync(), isTrue);
        final content = testFile.readAsStringSync();
        expect(content.contains('AuthCubit'), isTrue);
        expect(content.contains('blocTest'), isTrue);
      });
    });

    test('skips test file when withTests=false', () async {
      await h.withAuthFeature(() async {
        File(p.join(h.tempProject.path, 'pubspec.yaml')).writeAsStringSync(
          'name: test\n'
          'dependencies:\n'
          '  flutter_riverpod: ^2.4.0\n',
        );

        final gen = ProviderGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'auth', withTests: false);

        final testFile = File(
          p.join(
            h.tempProject.path,
            'test',
            'features',
            'auth',
            'presentation',
            'providers',
            'auth_provider_test.dart',
          ),
        );
        expect(testFile.existsSync(), isFalse);
      });
    });
  });

  group('EntityGenerator — tests', () {
    test('creates test file by default', () async {
      await h.withAuthFeature(() async {
        final gen = EntityGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user');

        final testFile = File(
          p.join(
            h.tempProject.path,
            'test',
            'features',
            'auth',
            'domain',
            'entities',
            'user_entity_test.dart',
          ),
        );
        expect(testFile.existsSync(), isTrue);
        final content = testFile.readAsStringSync();
        expect(content.contains('UserEntity'), isTrue);
        expect(content.contains('equals'), isTrue);
      });
    });

    test('skips test file when withTests=false', () async {
      await h.withAuthFeature(() async {
        final gen = EntityGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'user', withTests: false);

        final testFile = File(
          p.join(
            h.tempProject.path,
            'test',
            'features',
            'auth',
            'domain',
            'entities',
            'user_entity_test.dart',
          ),
        );
        expect(testFile.existsSync(), isFalse);
      });
    });
  });

  group('UseCaseGenerator — tests', () {
    test('creates test file by default', () async {
      await h.withAuthFeature(() async {
        final gen = UseCaseGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'login');

        final testFile = File(
          p.join(
            h.tempProject.path,
            'test',
            'features',
            'auth',
            'domain',
            'usecases',
            'login_usecase_test.dart',
          ),
        );
        expect(testFile.existsSync(), isTrue);
        final content = testFile.readAsStringSync();
        expect(content.contains('LoginUseCase'), isTrue);
        expect(content.contains('LoginParams'), isTrue);
      });
    });

    test('skips test file when withTests=false', () async {
      await h.withAuthFeature(() async {
        final gen = UseCaseGenerator(
          workingDirectory: h.tempProject.path,
          templatesRootOverride: h.projectRoot,
        );
        await gen.generate('auth', 'login', withTests: false);

        final testFile = File(
          p.join(
            h.tempProject.path,
            'test',
            'features',
            'auth',
            'domain',
            'usecases',
            'login_usecase_test.dart',
          ),
        );
        expect(testFile.existsSync(), isFalse);
      });
    });
  });
}
