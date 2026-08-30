import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/project_file_writer.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempProject;
  late ProjectFileWriter writer;

  setUp(() {
    tempProject = Directory.systemTemp.createTempSync('pfw_test_');
    Directory(p.join(tempProject.path, 'lib', 'app'))
        .createSync(recursive: true);
    writer = ProjectFileWriter();
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
      expect(content.contains("import 'app/app_cubit.dart'"), isTrue);
      expect(content.contains('BlocProvider<AppCubit>'), isTrue);
      expect(content.contains('AppCubit()'), isTrue);
    });

    test(
      'creates app_cubit.dart with AppCubit and AppState when bloc',
      () async {
        await writer.configureProjectFiles(tempProject.path, {
          'state_management': 'bloc',
          'router': 'none',
          'theme': 'material3',
          'localization': false,
        });

        final cubitFile = File(
          p.join(tempProject.path, 'lib', 'app', 'app_cubit.dart'),
        );
        expect(cubitFile.existsSync(), isTrue);
        final content = cubitFile.readAsStringSync();
        expect(content.contains('class AppCubit'), isTrue);
        expect(content.contains('class AppState'), isTrue);
        expect(content.contains('Cubit<AppState>'), isTrue);
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
        File(p.join(tempProject.path, 'lib', 'app', 'app_cubit.dart'))
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
  });
}
