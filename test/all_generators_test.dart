import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/feature_generator.dart';
import 'package:rekeens_flutter_cli/generators/provider_generator.dart';
import 'package:rekeens_flutter_cli/generators/repository_generator.dart';
import 'package:rekeens_flutter_cli/generators/service_generator.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempProject;
  late String projectRoot;

  setUpAll(() {
    projectRoot = Directory.current.path;
  });

  setUp(() {
    tempProject = Directory.systemTemp.createTempSync('gen_test_');
    Directory(p.join(tempProject.path, 'lib', 'features'))
        .createSync(recursive: true);
    File(p.join(tempProject.path, 'pubspec.yaml'))
        .writeAsStringSync('name: test\n');
  });

  tearDown(() {
    if (tempProject.existsSync()) {
      tempProject.deleteSync(recursive: true);
    }
  });

  Future<void> withAuthFeature(Future<void> Function() body) async {
    final featureGen = FeatureGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );
    await featureGen.generate('auth');
    await body();
  }

  group('RepositoryGenerator', () {
    test('creates user_repository.dart with UserRepository class', () async {
      await withAuthFeature(() async {
        final gen = RepositoryGenerator(
          workingDirectory: tempProject.path,
          templatesRootOverride: projectRoot,
        );
        await gen.generate('auth', 'user');

        final file = File(
          p.join(
            tempProject.path,
            'lib',
            'features',
            'auth',
            'data',
            'repositories',
            'user_repository.dart',
          ),
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content.contains('class UserRepository'), isTrue);
      });
    });

    test('throws when file exists and force=false', () async {
      await withAuthFeature(() async {
        final gen = RepositoryGenerator(
          workingDirectory: tempProject.path,
          templatesRootOverride: projectRoot,
        );
        await gen.generate('auth', 'user');

        expect(() => gen.generate('auth', 'user'), throwsA(isA<Exception>()));
      });
    });

    test('overwrites when file exists and force=true', () async {
      await withAuthFeature(() async {
        final gen = RepositoryGenerator(
          workingDirectory: tempProject.path,
          templatesRootOverride: projectRoot,
        );
        await gen.generate('auth', 'user');

        await gen.generate('auth', 'user', force: true);

        final file = File(
          p.join(
            tempProject.path,
            'lib',
            'features',
            'auth',
            'data',
            'repositories',
            'user_repository.dart',
          ),
        );
        expect(file.existsSync(), isTrue);
        expect(
          file.readAsStringSync().contains('class UserRepository'),
          isTrue,
        );
      });
    });

    test('throws on invalid name (UserProfile)', () async {
      await withAuthFeature(() async {
        final gen = RepositoryGenerator(
          workingDirectory: tempProject.path,
          templatesRootOverride: projectRoot,
        );
        expect(
          () => gen.generate('auth', 'UserProfile'),
          throwsA(isA<Exception>()),
        );
      });
    });

    test('throws when feature does not exist', () async {
      final gen = RepositoryGenerator(
        workingDirectory: tempProject.path,
        templatesRootOverride: projectRoot,
      );
      expect(() => gen.generate('missing', 'user'), throwsA(isA<Exception>()));
    });
  });

  group('ServiceGenerator', () {
    test('creates auth_service.dart with AuthService class', () async {
      await withAuthFeature(() async {
        final gen = ServiceGenerator(
          workingDirectory: tempProject.path,
          templatesRootOverride: projectRoot,
        );
        await gen.generate('auth', 'auth');

        final file = File(
          p.join(
            tempProject.path,
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
      await withAuthFeature(() async {
        final gen = ServiceGenerator(
          workingDirectory: tempProject.path,
          templatesRootOverride: projectRoot,
        );
        await gen.generate('auth', 'auth');

        expect(() => gen.generate('auth', 'auth'), throwsA(isA<Exception>()));
      });
    });

    test('overwrites when file exists and force=true', () async {
      await withAuthFeature(() async {
        final gen = ServiceGenerator(
          workingDirectory: tempProject.path,
          templatesRootOverride: projectRoot,
        );
        await gen.generate('auth', 'auth');

        await gen.generate('auth', 'auth', force: true);

        final file = File(
          p.join(
            tempProject.path,
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
      await withAuthFeature(() async {
        final gen = ServiceGenerator(
          workingDirectory: tempProject.path,
          templatesRootOverride: projectRoot,
        );
        expect(
          () => gen.generate('auth', 'UserProfile'),
          throwsA(isA<Exception>()),
        );
      });
    });

    test('throws when feature does not exist', () async {
      final gen = ServiceGenerator(
        workingDirectory: tempProject.path,
        templatesRootOverride: projectRoot,
      );
      expect(() => gen.generate('missing', 'auth'), throwsA(isA<Exception>()));
    });
  });

  group('ProviderGenerator', () {
    test(
      'creates auth_provider.dart with AuthProvider class and authProvider',
      () async {
        await withAuthFeature(() async {
          final gen = ProviderGenerator(
            workingDirectory: tempProject.path,
            templatesRootOverride: projectRoot,
          );
          await gen.generate('auth', 'auth');

          final file = File(
            p.join(
              tempProject.path,
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
      await withAuthFeature(() async {
        final gen = ProviderGenerator(
          workingDirectory: tempProject.path,
          templatesRootOverride: projectRoot,
        );
        await gen.generate('auth', 'auth');

        expect(() => gen.generate('auth', 'auth'), throwsA(isA<Exception>()));
      });
    });

    test('overwrites when file exists and force=true', () async {
      await withAuthFeature(() async {
        final gen = ProviderGenerator(
          workingDirectory: tempProject.path,
          templatesRootOverride: projectRoot,
        );
        await gen.generate('auth', 'auth');

        await gen.generate('auth', 'auth', force: true);

        final file = File(
          p.join(
            tempProject.path,
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
      await withAuthFeature(() async {
        final gen = ProviderGenerator(
          workingDirectory: tempProject.path,
          templatesRootOverride: projectRoot,
        );
        expect(
          () => gen.generate('auth', 'UserProfile'),
          throwsA(isA<Exception>()),
        );
      });
    });

    test('throws when feature does not exist', () async {
      final gen = ProviderGenerator(
        workingDirectory: tempProject.path,
        templatesRootOverride: projectRoot,
      );
      expect(() => gen.generate('missing', 'auth'), throwsA(isA<Exception>()));
    });
  });

  group('ProviderGenerator (bloc)', () {
    test(
      'creates auth_cubit.dart and auth_state.dart when stateManagement=bloc',
      () async {
        await withAuthFeature(() async {
          final gen = ProviderGenerator(
            workingDirectory: tempProject.path,
            templatesRootOverride: projectRoot,
          );
          await gen.generate('auth', 'auth', stateManagement: 'bloc');

          final cubitFile = File(
            p.join(
              tempProject.path,
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
              tempProject.path,
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
      await withAuthFeature(() async {
        // Simulate a project that uses flutter_bloc.
        File(p.join(tempProject.path, 'pubspec.yaml')).writeAsStringSync(
          'name: test\n'
          'dependencies:\n'
          '  flutter_bloc: ^8.1.0\n',
        );

        final gen = ProviderGenerator(
          workingDirectory: tempProject.path,
          templatesRootOverride: projectRoot,
        );
        await gen.generate('auth', 'auth');

        final cubitFile = File(
          p.join(
            tempProject.path,
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
      await withAuthFeature(() async {
        File(p.join(tempProject.path, 'pubspec.yaml')).writeAsStringSync(
          'name: test\n'
          'dependencies:\n'
          '  flutter_riverpod: ^2.4.0\n',
        );

        final gen = ProviderGenerator(
          workingDirectory: tempProject.path,
          templatesRootOverride: projectRoot,
        );
        await gen.generate('auth', 'auth');

        final providerFile = File(
          p.join(
            tempProject.path,
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
}
