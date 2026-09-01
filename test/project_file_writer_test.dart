import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/project_file_writer.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  late Directory tempProject;
  late ProjectFileWriter writer;
  late String projectRoot;

  setUpAll(() {
    projectRoot = Directory.current.path;
  });

  setUp(() {
    tempProject = Directory.systemTemp.createTempSync('pfw_test_');
    Directory(p.join(tempProject.path, 'lib', 'app'))
        .createSync(recursive: true);
    writer = ProjectFileWriter(templatesRootOverride: projectRoot);
  });

  tearDown(() {
    if (tempProject.existsSync()) {
      tempProject.deleteSync(recursive: true);
    }
  });

  group('ProjectFileWriter main.dart', () {
    test('wraps app in BlocProvider when state_management=bloc', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'bloc',
        'router': 'none',
        'theme': 'material3',
        'localization': false,
      });

      final mainFile = File(p.join(tempProject.path, 'lib', 'main.dart'));
      expect(mainFile.existsSync(), isTrue);
      final content = mainFile.readAsStringSync();
      expect(
        content.contains("import 'package:flutter_bloc/flutter_bloc.dart'"),
        isTrue,
      );
      expect(content.contains("import 'core/state/app_cubit.dart'"), isTrue);
      expect(content.contains('BlocProvider<AppCubit>'), isTrue);
      expect(content.contains('AppCubit()'), isTrue);
    });

    test(
      'creates app_cubit.dart and app_state.dart in core/state when bloc',
      () async {
        await writer.configureProjectFiles(tempProject.path, {
          'state_management': 'bloc',
          'router': 'none',
          'theme': 'material3',
          'localization': false,
        });

        final cubitFile = File(
          p.join(tempProject.path, 'lib', 'core', 'state', 'app_cubit.dart'),
        );
        expect(cubitFile.existsSync(), isTrue);
        final cubitContent = cubitFile.readAsStringSync();
        expect(cubitContent.contains('class AppCubit'), isTrue);
        expect(cubitContent.contains('Cubit<AppState>'), isTrue);
        expect(cubitContent.contains("import 'app_state.dart'"), isTrue);

        final stateFile = File(
          p.join(tempProject.path, 'lib', 'core', 'state', 'app_state.dart'),
        );
        expect(stateFile.existsSync(), isTrue);
        final stateContent = stateFile.readAsStringSync();
        expect(stateContent.contains('class AppState'), isTrue);
        expect(stateContent.contains('copyWith'), isTrue);
      },
    );

    test('wraps app in ProviderScope when state_management=riverpod', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'riverpod',
        'router': 'none',
        'theme': 'material3',
        'localization': false,
      });

      final mainFile = File(p.join(tempProject.path, 'lib', 'main.dart'));
      expect(mainFile.existsSync(), isTrue);
      final content = mainFile.readAsStringSync();
      expect(
        content.contains(
          "import 'package:flutter_riverpod/flutter_riverpod.dart'",
        ),
        isTrue,
      );
      expect(content.contains('ProviderScope'), isTrue);
      expect(
        File(p.join(tempProject.path, 'lib', 'core', 'state', 'app_cubit.dart'))
            .existsSync(),
        isFalse,
      );
    });

    test('uses plain runApp when state_management=none', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'none',
        'router': 'none',
        'theme': 'material3',
        'localization': false,
      });

      final mainFile = File(p.join(tempProject.path, 'lib', 'main.dart'));
      expect(mainFile.existsSync(), isTrue);
      final content = mainFile.readAsStringSync();
      expect(content.contains('runApp(const App())'), isTrue);
      expect(content.contains('ProviderScope'), isFalse);
      expect(content.contains('BlocProvider'), isFalse);
    });
  });

  group('ProjectFileWriter app.dart router', () {
    test(
      'uses MaterialApp.router with go_router when router=go_router',
      () async {
        await writer.configureProjectFiles(tempProject.path, {
          'state_management': 'none',
          'router': 'go_router',
          'theme': 'material3',
          'localization': false,
        });

        final appFile = File(
          p.join(tempProject.path, 'lib', 'app', 'app.dart'),
        );
        final content = appFile.readAsStringSync();
        expect(content.contains('MaterialApp.router'), isTrue);
        expect(content.contains('routerConfig: appRouter'), isTrue);
        expect(content.contains("import 'router.dart'"), isTrue);
      },
    );

    test('uses plain MaterialApp with home when router=none', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'none',
        'router': 'none',
        'theme': 'material3',
        'localization': false,
      });

      final appFile = File(p.join(tempProject.path, 'lib', 'app', 'app.dart'));
      final content = appFile.readAsStringSync();
      expect(content.contains('MaterialApp('), isTrue);
      expect(content.contains('home: const HomePage()'), isTrue);
      expect(content.contains('routerConfig'), isFalse);
    });
  });

  group('ProjectFileWriter router.dart', () {
    test('creates GoRouter config when router=go_router', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'none',
        'router': 'go_router',
        'theme': 'material3',
        'localization': false,
      });

      final routerFile = File(
        p.join(tempProject.path, 'lib', 'app', 'router.dart'),
      );
      expect(routerFile.existsSync(), isTrue);
      final content = routerFile.readAsStringSync();
      expect(
        content.contains("import 'package:go_router/go_router.dart'"),
        isTrue,
      );
      expect(content.contains('GoRouter'), isTrue);
      expect(content.contains("path: '/'"), isTrue);
    });

    test('creates simple AppRouter class when router=none', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'none',
        'router': 'none',
        'theme': 'material3',
        'localization': false,
      });

      final routerFile = File(
        p.join(tempProject.path, 'lib', 'app', 'router.dart'),
      );
      expect(routerFile.existsSync(), isTrue);
      final content = routerFile.readAsStringSync();
      expect(content.contains('class AppRouter'), isTrue);
      expect(content.contains("static const String home = '/'"), isTrue);
      expect(content.contains('GoRouter'), isFalse);
    });
  });

  group('ProjectFileWriter theme', () {
    test('uses useMaterial3: true and ColorScheme for material3', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'none',
        'router': 'none',
        'theme': 'material3',
        'localization': false,
      });

      final appFile = File(p.join(tempProject.path, 'lib', 'app', 'app.dart'));
      final content = appFile.readAsStringSync();
      expect(content.contains('useMaterial3: true'), isTrue);
      expect(content.contains('ColorScheme.fromSeed'), isTrue);
    });

    test('uses useMaterial3: false and primarySwatch for material2', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'none',
        'router': 'none',
        'theme': 'material2',
        'localization': false,
      });

      final appFile = File(p.join(tempProject.path, 'lib', 'app', 'app.dart'));
      final content = appFile.readAsStringSync();
      expect(content.contains('useMaterial3: false'), isTrue);
      expect(content.contains('primarySwatch: Colors.blue'), isTrue);
      expect(content.contains('ColorScheme.fromSeed'), isFalse);
    });
  });

  group('ProjectFileWriter localization', () {
    test('creates l10n directory and files when localization=true', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'none',
        'router': 'none',
        'theme': 'material3',
        'localization': true,
      });

      final l10nDir = Directory(p.join(tempProject.path, 'lib', 'l10n'));
      expect(l10nDir.existsSync(), isTrue);

      final l10nYaml = File(p.join(tempProject.path, 'l10n.yaml'));
      expect(l10nYaml.existsSync(), isTrue);
      final l10nContent = l10nYaml.readAsStringSync();
      expect(l10nContent.contains('arb-dir: lib/l10n'), isTrue);
      expect(l10nContent.contains('template-arb-file: app_en.arb'), isTrue);

      final arbFile = File(p.join(l10nDir.path, 'app_en.arb'));
      expect(arbFile.existsSync(), isTrue);
      final arbContent = arbFile.readAsStringSync();
      expect(arbContent.contains('appTitle'), isTrue);
    });

    test('replaces project_name placeholder in ARB file', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'none',
        'router': 'none',
        'theme': 'material3',
        'localization': true,
      });

      final arbFile = File(
        p.join(tempProject.path, 'lib', 'l10n', 'app_en.arb'),
      );
      final content = arbFile.readAsStringSync();
      expect(content.contains('{{project_name}}'), isFalse);
      expect(content.contains(tempProject.path), isTrue);
    });

    test(
      'adds localization delegates to app.dart when localization=true',
      () async {
        await writer.configureProjectFiles(tempProject.path, {
          'state_management': 'none',
          'router': 'none',
          'theme': 'material3',
          'localization': true,
        });

        final appFile = File(
          p.join(tempProject.path, 'lib', 'app', 'app.dart'),
        );
        final content = appFile.readAsStringSync();
        expect(content.contains('localizationsDelegates'), isTrue);
        expect(content.contains('supportedLocales'), isTrue);
        expect(
          content.contains("import '../l10n/app_localizations.dart'"),
          isTrue,
        );
      },
    );

    test('does not create l10n files when localization=false', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'none',
        'router': 'none',
        'theme': 'material3',
        'localization': false,
      });

      expect(
        Directory(p.join(tempProject.path, 'lib', 'l10n')).existsSync(),
        isFalse,
      );
      expect(File(p.join(tempProject.path, 'l10n.yaml')).existsSync(), isFalse);
    });
  });

  group('ProjectFileWriter networking', () {
    test(
      'creates dio client files in lib/core/network when networking=dio',
      () async {
        await writer.configureProjectFiles(tempProject.path, {
          'state_management': 'none',
          'router': 'none',
          'networking': 'dio',
          'theme': 'material3',
          'localization': false,
        });

        final networkDir = Directory(
          p.join(tempProject.path, 'lib', 'core', 'network'),
        );
        expect(networkDir.existsSync(), isTrue);

        final configFile = File(p.join(networkDir.path, 'network_config.dart'));
        expect(configFile.existsSync(), isTrue);
        final configContent = configFile.readAsStringSync();
        expect(configContent.contains('class NetworkConfig'), isTrue);
        expect(configContent.contains('TokenProvider'), isTrue);

        final exceptionFile = File(
          p.join(networkDir.path, 'api_exception.dart'),
        );
        expect(exceptionFile.existsSync(), isTrue);
        expect(
          exceptionFile.readAsStringSync().contains('class ApiException'),
          isTrue,
        );

        final dioFile = File(p.join(networkDir.path, 'dio_client.dart'));
        expect(dioFile.existsSync(), isTrue);
        final dioContent = dioFile.readAsStringSync();
        expect(dioContent.contains("import 'package:dio/dio.dart'"), isTrue);
        expect(dioContent.contains('class DioClient'), isTrue);
        expect(dioContent.contains('_AuthInterceptor'), isTrue);
        expect(dioContent.contains('LogInterceptor'), isTrue);
        expect(dioContent.contains('ApiException'), isTrue);

        expect(
          File(p.join(networkDir.path, 'http_client.dart')).existsSync(),
          isFalse,
        );
      },
    );

    test(
      'creates http client files in lib/core/network when networking=http',
      () async {
        await writer.configureProjectFiles(tempProject.path, {
          'state_management': 'none',
          'router': 'none',
          'networking': 'http',
          'theme': 'material3',
          'localization': false,
        });

        final networkDir = Directory(
          p.join(tempProject.path, 'lib', 'core', 'network'),
        );
        expect(networkDir.existsSync(), isTrue);

        expect(
          File(p.join(networkDir.path, 'network_config.dart')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(networkDir.path, 'api_exception.dart')).existsSync(),
          isTrue,
        );

        final httpFile = File(p.join(networkDir.path, 'http_client.dart'));
        expect(httpFile.existsSync(), isTrue);
        final httpContent = httpFile.readAsStringSync();
        expect(
          httpContent.contains("import 'package:http/http.dart' as http"),
          isTrue,
        );
        expect(httpContent.contains('class HttpClient'), isTrue);
        expect(httpContent.contains('Authorization'), isTrue);
        expect(httpContent.contains('ApiException'), isTrue);

        expect(
          File(p.join(networkDir.path, 'dio_client.dart')).existsSync(),
          isFalse,
        );
      },
    );

    test('does not create network dir when networking=none', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'none',
        'router': 'none',
        'networking': 'none',
        'theme': 'material3',
        'localization': false,
      });

      expect(
        Directory(p.join(tempProject.path, 'lib', 'core', 'network'))
            .existsSync(),
        isFalse,
      );
    });

    test('does not create network dir when networking is omitted', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'none',
        'router': 'none',
        'theme': 'material3',
        'localization': false,
      });

      expect(
        Directory(p.join(tempProject.path, 'lib', 'core', 'network'))
            .existsSync(),
        isFalse,
      );
    });
  });

  group('ProjectFileWriter core/errors', () {
    test(
      'creates failure.dart and result.dart always, even without networking',
      () async {
        await writer.configureProjectFiles(tempProject.path, {
          'state_management': 'none',
          'router': 'none',
          'networking': 'none',
          'theme': 'material3',
          'localization': false,
        });

        final errorsDir = Directory(
          p.join(tempProject.path, 'lib', 'core', 'errors'),
        );
        expect(errorsDir.existsSync(), isTrue);

        final failureFile = File(p.join(errorsDir.path, 'failure.dart'));
        expect(failureFile.existsSync(), isTrue);
        final failureContent = failureFile.readAsStringSync();
        expect(failureContent.contains('sealed class Failure'), isTrue);
        expect(failureContent.contains('class ServerFailure'), isTrue);
        expect(failureContent.contains('class ClientFailure'), isTrue);
        expect(failureContent.contains('class NetworkFailure'), isTrue);
        expect(failureContent.contains('class CacheFailure'), isTrue);
        expect(failureContent.contains('class UnknownFailure'), isTrue);

        final resultFile = File(p.join(errorsDir.path, 'result.dart'));
        expect(resultFile.existsSync(), isTrue);
        final resultContent = resultFile.readAsStringSync();
        expect(resultContent.contains('sealed class Result<T>'), isTrue);
        expect(resultContent.contains('class Success<T>'), isTrue);
        expect(resultContent.contains('class FailureResult<T>'), isTrue);
        expect(resultContent.contains("import 'failure.dart'"), isTrue);
      },
    );

    test(
      'creates exception_to_failure_mapper.dart when networking=dio',
      () async {
        await writer.configureProjectFiles(tempProject.path, {
          'state_management': 'none',
          'router': 'none',
          'networking': 'dio',
          'theme': 'material3',
          'localization': false,
        });

        final mapperFile = File(
          p.join(
            tempProject.path,
            'lib',
            'core',
            'errors',
            'exception_to_failure_mapper.dart',
          ),
        );
        expect(mapperFile.existsSync(), isTrue);
        final content = mapperFile.readAsStringSync();
        expect(content.contains('Failure mapExceptionToFailure'), isTrue);
        expect(content.contains("import 'failure.dart'"), isTrue);
        expect(
          content.contains("import '../network/api_exception.dart'"),
          isTrue,
        );
        expect(content.contains('ServerFailure'), isTrue);
        expect(content.contains('ClientFailure'), isTrue);
        expect(content.contains('NetworkFailure'), isTrue);
        // Must NOT use package: imports — these are templates rendered into a
        // generated project whose name differs from the CLI package.
        expect(content.contains('package:rekeens_flutter_cli'), isFalse);
      },
    );

    test(
      'creates exception_to_failure_mapper.dart when networking=http',
      () async {
        await writer.configureProjectFiles(tempProject.path, {
          'state_management': 'none',
          'router': 'none',
          'networking': 'http',
          'theme': 'material3',
          'localization': false,
        });

        expect(
          File(
            p.join(
              tempProject.path,
              'lib',
              'core',
              'errors',
              'exception_to_failure_mapper.dart',
            ),
          ).existsSync(),
          isTrue,
        );
      },
    );

    test(
      'does not create exception_to_failure_mapper.dart when networking=none',
      () async {
        await writer.configureProjectFiles(tempProject.path, {
          'state_management': 'none',
          'router': 'none',
          'networking': 'none',
          'theme': 'material3',
          'localization': false,
        });

        expect(
          File(
            p.join(
              tempProject.path,
              'lib',
              'core',
              'errors',
              'exception_to_failure_mapper.dart',
            ),
          ).existsSync(),
          isFalse,
        );
      },
    );

    test('creates errors dir even when networking is omitted', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'none',
        'router': 'none',
        'theme': 'material3',
        'localization': false,
      });

      expect(
        Directory(p.join(tempProject.path, 'lib', 'core', 'errors'))
            .existsSync(),
        isTrue,
      );
      expect(
        File(
          p.join(
            tempProject.path,
            'lib',
            'core',
            'errors',
            'exception_to_failure_mapper.dart',
          ),
        ).existsSync(),
        isFalse,
      );
    });
  });

  group('ProjectFileWriter.enableFlutterGenerate', () {
    test('adds generate: true under flutter section', () async {
      final pubspec = File(p.join(tempProject.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: my_app
environment:
  sdk: ^3.0.0

flutter:
  uses-material-design: true
''');

      await writer.enableFlutterGenerate(tempProject.path);

      final content = pubspec.readAsStringSync();
      expect(content.contains('generate: true'), isTrue);
      final lines = content.split('\n');
      final flutterIdx = lines.indexOf('flutter:');
      final generateIdx = lines.indexOf('  generate: true');
      expect(generateIdx, greaterThan(flutterIdx));
    });

    test('does not duplicate generate: true if already present', () async {
      final pubspec = File(p.join(tempProject.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: my_app

flutter:
  generate: true
  uses-material-design: true
''');

      await writer.enableFlutterGenerate(tempProject.path);

      final content = pubspec.readAsStringSync();
      final count = 'generate: true'.allMatches(content).length;
      expect(count, 1);
    });

    test('appends flutter section if missing', () async {
      final pubspec = File(p.join(tempProject.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: my_app
environment:
  sdk: ^3.0.0
''');

      await writer.enableFlutterGenerate(tempProject.path);

      final content = pubspec.readAsStringSync();
      expect(content.contains('flutter:'), isTrue);
      expect(content.contains('generate: true'), isTrue);
    });

    test('does nothing if pubspec.yaml does not exist', () async {
      await writer.enableFlutterGenerate(tempProject.path);
      expect(
        File(p.join(tempProject.path, 'pubspec.yaml')).existsSync(),
        isFalse,
      );
    });

    test('preserves existing pubspec content', () async {
      final pubspec = File(p.join(tempProject.path, 'pubspec.yaml'));
      const original = '''
name: my_app
description: A test app
environment:
  sdk: ^3.0.0
''';
      pubspec.writeAsStringSync(original);

      await writer.enableFlutterGenerate(tempProject.path);

      final content = pubspec.readAsStringSync();
      expect(content.contains('name: my_app'), isTrue);
      expect(content.contains('description: A test app'), isTrue);
      expect(content.contains('sdk: ^3.0.0'), isTrue);
    });

    test('handles CRLF line endings', () async {
      final pubspec = File(p.join(tempProject.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync(
        'name: my_app\r\nenvironment:\r\n  sdk: ^3.0.0\r\n\r\n'
        'flutter:\r\n  uses-material-design: true\r\n',
      );

      await writer.enableFlutterGenerate(tempProject.path);

      final content = pubspec.readAsStringSync();
      expect(content.contains('generate: true'), isTrue);
      final reparsed = loadYaml(content) as YamlMap;
      expect(reparsed['flutter']['generate'], isTrue);
    });

    test('ignores generate in comments', () async {
      final pubspec = File(p.join(tempProject.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: my_app

flutter:
  # generate: true
  uses-material-design: true
''');

      await writer.enableFlutterGenerate(tempProject.path);

      final content = pubspec.readAsStringSync();
      final reparsed = loadYaml(content) as YamlMap;
      expect(reparsed['flutter']['generate'], isTrue);
      final generateCount = RegExp(
        r'^  generate: true$',
        multiLine: true,
      ).allMatches(content).length;
      expect(generateCount, 1);
    });

    test('preserves comments in pubspec', () async {
      final pubspec = File(p.join(tempProject.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
# This is a comment
name: my_app

flutter:
  # Another comment
  uses-material-design: true
''');

      await writer.enableFlutterGenerate(tempProject.path);

      final content = pubspec.readAsStringSync();
      expect(content.contains('# This is a comment'), isTrue);
      expect(content.contains('# Another comment'), isTrue);
      expect(content.contains('generate: true'), isTrue);
    });

    test('handles flutter section with only generate already true', () async {
      final pubspec = File(p.join(tempProject.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: my_app
flutter:
  generate: true
  uses-material-design: true
''');

      final original = pubspec.readAsStringSync();
      await writer.enableFlutterGenerate(tempProject.path);

      final content = pubspec.readAsStringSync();
      expect(content, original);
    });

    test('handles real flutter create pubspec format', () async {
      final pubspec = File(p.join(tempProject.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('''
name: myapp
description: "A new Flutter project."
publish_to: 'none'
version: 0.1.0

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
''');

      await writer.enableFlutterGenerate(tempProject.path);

      final content = pubspec.readAsStringSync();
      final reparsed = loadYaml(content) as YamlMap;
      expect(reparsed['flutter']['generate'], isTrue);
      expect(reparsed['flutter']['uses-material-design'], isTrue);
      expect(reparsed['name'], 'myapp');
      expect(reparsed['dependencies']['flutter']['sdk'], 'flutter');
    });
  });
}
