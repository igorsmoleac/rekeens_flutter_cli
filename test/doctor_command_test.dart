import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/commands/doctor_command.dart';
import 'package:test/test.dart';

ProcessResult _result({
  int exitCode = 0,
  String stdout = '',
  String stderr = '',
}) {
  return ProcessResult(0, exitCode, stdout, stderr);
}

void main() {
  group('extractVersion', () {
    late DoctorCommand command;

    setUp(() {
      command = DoctorCommand();
    });

    test('parses Dart SDK version', () {
      const output =
          'Dart SDK version: 3.5.0 (stable) (Tue Aug 27 00:00:00 2024)';
      expect(command.extractVersion('Dart', output), 'Dart 3.5.0');
    });

    test('parses Flutter version', () {
      const output = 'Flutter 3.24.0 • channel stable • https://github.com';
      expect(command.extractVersion('Flutter', output), 'Flutter 3.24.0');
    });

    test('strips non-ASCII bullet characters from Flutter output', () {
      const output = 'Flutter 3.24.0 \u2022 channel stable';
      final result = command.extractVersion('Flutter', output);
      expect(result.contains('\u2022'), isFalse);
      expect(result, 'Flutter 3.24.0');
    });

    test('replaces bullet with dash before stripping non-ASCII', () {
      const output = 'git version 2.45.0 \u2022 extra';
      final result = command.extractVersion('Git', output);
      expect(result.contains('- extra'), isTrue);
      expect(result.contains('\u2022'), isFalse);
    });

    test('returns trimmed first line for Git', () {
      const output = 'git version 2.45.0\nextra line';
      expect(command.extractVersion('Git', output), 'git version 2.45.0');
    });

    test('returns empty string for empty output', () {
      expect(command.extractVersion('Dart', ''), '');
    });

    test('returns trimmed line for whitespace-only output', () {
      expect(command.extractVersion('Dart', '   \n  '), '');
    });

    test('returns raw line when no known pattern matches', () {
      const output = 'some unknown tool 1.2.3';
      expect(
        command.extractVersion('Unknown', output),
        'some unknown tool 1.2.3',
      );
    });

    test('returns raw line for Dart output without SDK marker', () {
      const output = 'Dart 3.5.0 (stable)';
      expect(command.extractVersion('Dart', output), 'Dart 3.5.0 (stable)');
    });

    test('handles multiline Dart output by using first line', () {
      const output =
          'Dart SDK version: 3.5.0 (stable)\non "windows"\nmore info';
      expect(command.extractVersion('Dart', output), 'Dart 3.5.0');
    });

    test('parses Xcode version from xcodebuild output', () {
      const output = 'Xcode 15.4\nBuild version 15F31d';
      expect(command.extractVersion('Xcode', output), 'Xcode 15.4');
    });

    test('parses Chrome version from --version output', () {
      const output = 'Google Chrome 126.0.6478.126';
      expect(command.extractVersion('Chrome', output), 'Chrome 126.0.6478.126');
    });

    test('parses Chromium version from --version output', () {
      const output = 'Chromium 125.0.6422.112 built on Debian';
      expect(command.extractVersion('Chrome', output), 'Chrome 125.0.6422.112');
    });

    test('returns raw line for Chrome output without numeric version', () {
      const output = 'Google Chrome unknown';
      expect(command.extractVersion('Chrome', output), 'Google Chrome unknown');
    });
  });

  group('DoctorCommand.run (process runner injection)', () {
    late Directory tempDir;
    late Map<String, String> env;

    setUp(() {
      exitCode = 0;
      tempDir = Directory.systemTemp.createTempSync('doctor_run_test_');
      env = <String, String>{};
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('reports all core tools ok when runner succeeds', () async {
      final calls = <String>[];
      final command = DoctorCommand(
        processRunner: (executable, args, {environment}) async {
          calls.add('$executable ${args.join(' ')}');
          if (executable == 'cmd') {
            if (args.contains('Dart')) {
              return _result(stdout: 'Dart SDK version: 3.5.0 (stable)');
            }
            if (args.contains('Flutter')) {
              return _result(stdout: 'Flutter 3.24.0');
            }
            if (args.contains('Git')) {
              return _result(stdout: 'git version 2.45.0');
            }
          }
          if (executable == 'Dart') {
            return _result(stdout: 'Dart SDK version: 3.5.0 (stable)');
          }
          if (executable == 'Flutter') {
            return _result(stdout: 'Flutter 3.24.0');
          }
          if (executable == 'Git') {
            return _result(stdout: 'git version 2.45.0');
          }
          return _result(stdout: '');
        },
        environment: env,
      );

      await command.run();

      expect(exitCode, 0);
      expect(calls, isNotEmpty);
    });

    test('sets exitCode=1 when a core tool is missing', () async {
      final command = DoctorCommand(
        processRunner: (executable, args, {environment}) async {
          if (executable == 'cmd' && args.contains('Git')) {
            throw ProcessException(executable, args);
          }
          if (executable == 'Git') {
            throw ProcessException(executable, args);
          }
          if (executable == 'cmd' && args.contains('Dart')) {
            return _result(stdout: 'Dart SDK version: 3.5.0');
          }
          if (executable == 'cmd' && args.contains('Flutter')) {
            return _result(stdout: 'Flutter 3.24.0');
          }
          if (executable == 'Dart') {
            return _result(stdout: 'Dart SDK version: 3.5.0');
          }
          if (executable == 'Flutter') {
            return _result(stdout: 'Flutter 3.24.0');
          }
          return _result(stdout: '');
        },
        environment: env,
      );

      await command.run();

      expect(exitCode, 1);
    });
  });

  group('Android SDK check', () {
    late Directory tempDir;

    setUp(() {
      exitCode = 0;
      tempDir = Directory.systemTemp.createTempSync('doctor_android_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test(
      'reports Android SDK when ANDROID_HOME points to existing dir',
      () async {
        final command = DoctorCommand(
          processRunner: (executable, args, {environment}) async {
            if (executable == 'cmd' && args.contains('Dart')) {
              return _result(stdout: 'Dart SDK version: 3.5.0');
            }
            if (executable == 'cmd' && args.contains('Flutter')) {
              return _result(stdout: 'Flutter 3.24.0');
            }
            if (executable == 'cmd' && args.contains('Git')) {
              return _result(stdout: 'git version 2.45.0');
            }
            if (executable == 'Dart') {
              return _result(stdout: 'Dart SDK version: 3.5.0');
            }
            if (executable == 'Flutter') {
              return _result(stdout: 'Flutter 3.24.0');
            }
            if (executable == 'Git') {
              return _result(stdout: 'git version 2.45.0');
            }
            throw ProcessException(executable, args);
          },
          environment: {'ANDROID_HOME': tempDir.path},
        );

        await command.run();
        expect(exitCode, 0);
      },
    );

    test('reports Android SDK missing when env vars not set', () async {
      final command = DoctorCommand(
        processRunner: (executable, args, {environment}) async {
          if (executable == 'cmd' && args.contains('Dart')) {
            return _result(stdout: 'Dart SDK version: 3.5.0');
          }
          if (executable == 'cmd' && args.contains('Flutter')) {
            return _result(stdout: 'Flutter 3.24.0');
          }
          if (executable == 'cmd' && args.contains('Git')) {
            return _result(stdout: 'git version 2.45.0');
          }
          if (executable == 'Dart') {
            return _result(stdout: 'Dart SDK version: 3.5.0');
          }
          if (executable == 'Flutter') {
            return _result(stdout: 'Flutter 3.24.0');
          }
          if (executable == 'Git') {
            return _result(stdout: 'git version 2.45.0');
          }
          throw ProcessException(executable, args);
        },
        environment: <String, String>{},
      );

      await command.run();
      expect(exitCode, 0);
    });

    test('reports Android SDK missing when path does not exist', () async {
      final command = DoctorCommand(
        processRunner: (executable, args, {environment}) async {
          if (executable == 'cmd' && args.contains('Dart')) {
            return _result(stdout: 'Dart SDK version: 3.5.0');
          }
          if (executable == 'cmd' && args.contains('Flutter')) {
            return _result(stdout: 'Flutter 3.24.0');
          }
          if (executable == 'cmd' && args.contains('Git')) {
            return _result(stdout: 'git version 2.45.0');
          }
          if (executable == 'Dart') {
            return _result(stdout: 'Dart SDK version: 3.5.0');
          }
          if (executable == 'Flutter') {
            return _result(stdout: 'Flutter 3.24.0');
          }
          if (executable == 'Git') {
            return _result(stdout: 'git version 2.45.0');
          }
          throw ProcessException(executable, args);
        },
        environment: {'ANDROID_HOME': p.join(tempDir.path, 'nonexistent')},
      );

      await command.run();
      expect(exitCode, 0);
    });
  });

  group('Chrome check', () {
    setUp(() {
      exitCode = 0;
    });

    test('reports Chrome found when --version succeeds', () async {
      final command = DoctorCommand(
        processRunner: (executable, args, {environment}) async {
          if (executable == 'cmd' && args.contains('Dart')) {
            return _result(stdout: 'Dart SDK version: 3.5.0');
          }
          if (executable == 'cmd' && args.contains('Flutter')) {
            return _result(stdout: 'Flutter 3.24.0');
          }
          if (executable == 'cmd' && args.contains('Git')) {
            return _result(stdout: 'git version 2.45.0');
          }
          if (executable == 'cmd' && args.contains('chrome')) {
            return _result(stdout: 'Google Chrome 126.0.6478.126');
          }
          if (executable == 'Dart') {
            return _result(stdout: 'Dart SDK version: 3.5.0');
          }
          if (executable == 'Flutter') {
            return _result(stdout: 'Flutter 3.24.0');
          }
          if (executable == 'Git') {
            return _result(stdout: 'git version 2.45.0');
          }
          if (executable == 'google-chrome') {
            return _result(stdout: 'Google Chrome 126.0.6478.126');
          }
          throw ProcessException(executable, args);
        },
        environment: <String, String>{},
      );

      await command.run();
      expect(exitCode, 0);
    });

    test('reports Chrome not found when all candidates fail', () async {
      final command = DoctorCommand(
        processRunner: (executable, args, {environment}) async {
          if (executable == 'cmd' && args.contains('Dart')) {
            return _result(stdout: 'Dart SDK version: 3.5.0');
          }
          if (executable == 'cmd' && args.contains('Flutter')) {
            return _result(stdout: 'Flutter 3.24.0');
          }
          if (executable == 'cmd' && args.contains('Git')) {
            return _result(stdout: 'git version 2.45.0');
          }
          if (executable == 'Dart') {
            return _result(stdout: 'Dart SDK version: 3.5.0');
          }
          if (executable == 'Flutter') {
            return _result(stdout: 'Flutter 3.24.0');
          }
          if (executable == 'Git') {
            return _result(stdout: 'git version 2.45.0');
          }
          throw ProcessException(executable, args);
        },
        environment: <String, String>{},
      );

      await command.run();
      expect(exitCode, 0);
    });
  });
}
