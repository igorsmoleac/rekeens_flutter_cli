import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/provider_generator.dart';
import 'package:rekeens_flutter_cli/generators/repository_generator.dart';
import 'package:rekeens_flutter_cli/generators/service_generator.dart';
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

  group('ProviderGenerator', () {
    test(
      'creates auth_provider.dart with AuthProvider class and authProvider',
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
          expect(content.contains('class AuthProvider'), isTrue);
          expect(content.contains('authProvider'), isTrue);
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
        expect(file.readAsStringSync().contains('class AuthProvider'), isTrue);
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
          providerFile.readAsStringSync().contains('class AuthProvider'),
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
}
