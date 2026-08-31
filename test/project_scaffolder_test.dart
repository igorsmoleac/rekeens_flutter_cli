import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/project_file_writer.dart';
import 'package:rekeens_flutter_cli/services/project_scaffolder.dart';
import 'package:rekeens_flutter_cli/services/template_service.dart';
import 'package:rekeens_flutter_cli/utils/template_resolver.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempRoot;
  late Directory workingDir;
  late Directory fakeHome;
  late List<String> calls;
  late List<Duration?> timeoutCalls;
  late Directory projectDir;
  late String projectPath;
  late String projectRoot;

  setUpAll(() {
    projectRoot = Directory.current.path;
  });

  ScaffoldProcessRunner makeRunner({
    bool failFlutterCreate = false,
    bool createThenFail = false,
  }) {
    return (executable, args, {workingDirectory, timeout}) async {
      final cmd =
          '$executable ${args.join(' ')}'
          '${workingDirectory != null ? ' (cwd=$workingDirectory)' : ''}';
      calls.add(cmd);
      timeoutCalls.add(timeout);

      if (executable == 'flutter' && args.first == 'create') {
        if (createThenFail) {
          // Simulate partial creation then failure.
          projectDir.createSync(recursive: true);
          throw ProcessException('flutter', args);
        }
        if (failFlutterCreate) {
          throw ProcessException('flutter', args);
        }
        // Simulate `flutter create` by building the expected skeleton.
        Directory(p.join(workingDir.path, 'my_app', 'lib', 'app'))
            .createSync(recursive: true);
        return;
      }

      // All other commands succeed as no-ops.
      return;
    };
  }

  ProjectScaffolder makeScaffolder(ScaffoldProcessRunner runner) {
    return ProjectScaffolder(
      templateService: const TemplateService(),
      templateResolver: TemplateResolver(homeDirectoryOverride: fakeHome.path),
      projectFileWriter: ProjectFileWriter(
        templatesRootOverride: projectRoot,
        workingDirectory: workingDir.path,
      ),
      processRunner: runner,
      workingDirectory: workingDir.path,
    );
  }

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('scaffolder_test_');
    workingDir = Directory(p.join(tempRoot.path, 'project'))..createSync();
    fakeHome = Directory(p.join(tempRoot.path, 'home'))..createSync();
    calls = <String>[];
    timeoutCalls = <Duration?>[];
    projectDir = Directory(p.join(workingDir.path, 'my_app'));
    projectPath = projectDir.path;
  });

  tearDown(() {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  void createBaseTemplate() {
    final baseDir = Directory(
      p.join(workingDir.path, '.rekeens', 'templates', 'base'),
    )..createSync(recursive: true);
    File(p.join(baseDir.path, 'marker.txt')).writeAsStringSync('base');
  }

  group('ProjectScaffolder.scaffold — pipeline order', () {
    test('runs full pipeline with codegen and localization', () async {
      createBaseTemplate();
      final scaffolder = makeScaffolder(makeRunner());

      await scaffolder.scaffold('my_app', {
        'platforms': ['android', 'ios'],
        'architecture': 'feature-first',
        'state_management': 'riverpod',
        'router': 'go_router',
        'networking': 'dio',
        'localization': true,
        'theme': 'material3',
        'codegen': true,
      });

      expect(calls.length, 9);
      expect(
        calls[0],
        startsWith('flutter create --platforms=android,ios my_app'),
      );
      // Dependencies are added in a single pub add call.
      expect(calls[1], startsWith('flutter pub add '));
      expect(calls[1], contains('flutter_riverpod:'));
      expect(calls[1], contains('go_router:'));
      expect(calls[1], contains('dio:'));
      expect(calls[1], contains('intl:'));
      expect(calls[1], isNot(contains('--dev')));
      // Dev dependencies.
      expect(calls[2], startsWith('flutter pub add --dev build_runner:'));
      expect(calls[2], contains('freezed:'));
      expect(calls[2], contains('json_serializable:'));
      // Localization pipeline.
      expect(
        calls[3],
        'flutter pub add flutter_localizations --sdk=flutter (cwd=$projectPath)',
      );
      expect(calls[4], 'flutter pub get (cwd=$projectPath)');
      expect(calls[5], 'flutter gen-l10n (cwd=$projectPath)');
      expect(calls[6], 'flutter pub get (cwd=$projectPath)');
      // Format + analyze.
      expect(calls[7], 'dart format . (cwd=$projectPath)');
      expect(calls[8], 'flutter analyze (cwd=$projectPath)');

      // Template was copied.
      expect(File(p.join(projectDir.path, 'marker.txt')).existsSync(), isTrue);
      // Project files were configured.
      expect(
        File(p.join(projectDir.path, 'lib', 'main.dart')).existsSync(),
        isTrue,
      );
    });

    test('skips codegen and localization when disabled', () async {
      createBaseTemplate();
      final scaffolder = makeScaffolder(makeRunner());

      await scaffolder.scaffold('my_app', {
        'platforms': ['android'],
        'architecture': 'feature-first',
        'state_management': 'none',
        'router': 'none',
        'networking': 'none',
        'localization': false,
        'theme': 'material3',
        'codegen': false,
      });

      // Only create + format + analyze (no pub add, no l10n, no dev deps).
      expect(calls, [
        startsWith('flutter create --platforms=android my_app'),
        'dart format . (cwd=$projectPath)',
        'flutter analyze (cwd=$projectPath)',
      ]);
    });

    test('omits --platforms when platforms list is empty', () async {
      createBaseTemplate();
      final scaffolder = makeScaffolder(makeRunner());

      await scaffolder.scaffold('my_app', {
        'platforms': <String>[],
        'architecture': 'feature-first',
        'state_management': 'none',
        'router': 'none',
        'networking': 'none',
        'localization': false,
        'theme': 'material3',
        'codegen': false,
      });

      expect(calls.first, 'flutter create my_app');
    });
  });

  group('ProjectScaffolder.scaffold — error handling', () {
    test('rethrows wrapped exception when flutter create fails', () async {
      createBaseTemplate();
      final scaffolder = makeScaffolder(makeRunner(failFlutterCreate: true));

      expect(
        () => scaffolder.scaffold('my_app', {
          'platforms': ['android'],
          'architecture': 'feature-first',
          'state_management': 'none',
          'router': 'none',
          'networking': 'none',
          'localization': false,
          'theme': 'material3',
          'codegen': false,
        }),
        throwsA(isA<Exception>()),
      );
    });

    test('cleans up partial project dir when flutter create fails', () async {
      createBaseTemplate();
      final scaffolder = makeScaffolder(makeRunner(createThenFail: true));

      Object? thrown;
      try {
        await scaffolder.scaffold('my_app', {
          'platforms': ['android'],
          'architecture': 'feature-first',
          'state_management': 'none',
          'router': 'none',
          'networking': 'none',
          'localization': false,
          'theme': 'material3',
          'codegen': false,
        });
      } catch (e) {
        thrown = e;
      }

      expect(thrown, isA<Exception>());
      // The partial project dir should have been removed.
      expect(projectDir.existsSync(), isFalse);
    });
  });

  group('ProjectScaffolder.scaffold — timeouts', () {
    test('passes correct timeout for each process call', () async {
      createBaseTemplate();
      final scaffolder = makeScaffolder(makeRunner());

      await scaffolder.scaffold('my_app', {
        'platforms': ['android', 'ios'],
        'architecture': 'feature-first',
        'state_management': 'riverpod',
        'router': 'go_router',
        'networking': 'dio',
        'localization': true,
        'theme': 'material3',
        'codegen': true,
      });

      expect(timeoutCalls.length, 9);
      expect(timeoutCalls[0], ProcessTimeouts.create);
      expect(timeoutCalls[1], ProcessTimeouts.pub);
      expect(timeoutCalls[2], ProcessTimeouts.pub);
      expect(timeoutCalls[3], ProcessTimeouts.pub);
      expect(timeoutCalls[4], ProcessTimeouts.pub);
      expect(timeoutCalls[5], ProcessTimeouts.genL10n);
      expect(timeoutCalls[6], ProcessTimeouts.pub);
      expect(timeoutCalls[7], ProcessTimeouts.format);
      expect(timeoutCalls[8], ProcessTimeouts.analyze);
    });

    test(
      'passes timeouts even when localization and codegen are disabled',
      () async {
        createBaseTemplate();
        final scaffolder = makeScaffolder(makeRunner());

        await scaffolder.scaffold('my_app', {
          'platforms': ['android'],
          'architecture': 'feature-first',
          'state_management': 'none',
          'router': 'none',
          'networking': 'none',
          'localization': false,
          'theme': 'material3',
          'codegen': false,
        });

        expect(timeoutCalls.length, 3);
        expect(timeoutCalls[0], ProcessTimeouts.create);
        expect(timeoutCalls[1], ProcessTimeouts.format);
        expect(timeoutCalls[2], ProcessTimeouts.analyze);
      },
    );
  });

  group('defaultScaffoldProcessRunner — timeout', () {
    // Run sequentially: defaultScaffoldProcessRunner pipes to global
    // stdout/stderr which cannot be called concurrently.
    test(
      'timeout behavior: kills on timeout, completes when within bounds',
      () async {
        await expectLater(
          defaultScaffoldProcessRunner(
            Platform.isWindows ? 'ping' : 'sleep',
            Platform.isWindows ? ['-t', 'localhost'] : ['30'],
            timeout: const Duration(milliseconds: 200),
          ),
          throwsA(isA<TimeoutException>()),
        );

        await defaultScaffoldProcessRunner('echo', [
          'hello',
        ], timeout: const Duration(seconds: 10));

        await defaultScaffoldProcessRunner('echo', ['no-timeout']);
      },
    );
  });
}
