import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/commands/config_command.dart';
import 'package:rekeens_flutter_cli/config/config_loader.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('config_init_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  CommandRunner<void> runnerWithDir() {
    final runner = CommandRunner<void>('rekeens', 'Rekeens CLI test runner');
    runner.addCommand(ConfigCommand(workingDirectory: tempDir.path));
    return runner;
  }

  File configFile() => File(p.join(tempDir.path, 'rekeens.yaml'));

  group('ConfigInitCommand', () {
    test('creates rekeens.yaml with default content', () async {
      await runnerWithDir().run(['config', 'init']);

      expect(configFile().existsSync(), isTrue);
      expect(
        configFile().readAsStringSync(),
        ConfigInitCommand.defaultConfigContent,
      );
    });

    test('created config is loadable by ConfigLoader', () async {
      await runnerWithDir().run(['config', 'init']);

      final loaded = ConfigLoader.load(workingDirectory: tempDir.path);
      expect(loaded, isNotNull);
      expect(loaded!['architecture'], 'feature-first');
      expect(loaded['state_management'], 'riverpod');
      expect(loaded['router'], 'go_router');
      expect(loaded['networking'], 'dio');
      expect(loaded['theme'], 'material3');
      expect(loaded['localization'], isFalse);
      expect(loaded['codegen'], isFalse);
      expect(loaded['platforms'], ['android', 'ios', 'windows', 'linux']);
    });

    test(
      'throws UsageException when file already exists and force=false',
      () async {
        configFile().writeAsStringSync('defaults:\n  theme: material2\n');

        expect(
          () => runnerWithDir().run(['config', 'init']),
          throwsA(isA<UsageException>()),
        );

        expect(
          configFile().readAsStringSync(),
          'defaults:\n  theme: material2\n',
        );
      },
    );

    test('overwrites existing file when force=true', () async {
      configFile().writeAsStringSync('defaults:\n  theme: material2\n');

      await runnerWithDir().run(['config', 'init', '--force']);

      expect(
        configFile().readAsStringSync(),
        ConfigInitCommand.defaultConfigContent,
      );
    });

    test('accepts -f abbreviation for force', () async {
      configFile().writeAsStringSync('defaults:\n  theme: material2\n');

      await runnerWithDir().run(['config', 'init', '-f']);

      expect(
        configFile().readAsStringSync(),
        ConfigInitCommand.defaultConfigContent,
      );
    });

    test('dry-run does not create the file', () async {
      await runnerWithDir().run(['config', 'init', '--dry-run']);

      expect(configFile().existsSync(), isFalse);
    });

    test('dry-run accepts -n abbreviation', () async {
      await runnerWithDir().run(['config', 'init', '-n']);

      expect(configFile().existsSync(), isFalse);
    });

    test('dry-run still throws when file exists and force=false', () async {
      configFile().writeAsStringSync('defaults:\n  theme: material2\n');

      expect(
        () => runnerWithDir().run(['config', 'init', '--dry-run']),
        throwsA(isA<UsageException>()),
      );

      expect(
        configFile().readAsStringSync(),
        'defaults:\n  theme: material2\n',
      );
    });

    test('dry-run with force previews overwrite without writing', () async {
      configFile().writeAsStringSync('defaults:\n  theme: material2\n');

      await runnerWithDir().run(['config', 'init', '--dry-run', '--force']);

      expect(
        configFile().readAsStringSync(),
        'defaults:\n  theme: material2\n',
      );
    });
  });

  group('ConfigCommand (runner integration)', () {
    test('throws UsageException when no subcommand given', () {
      final runner = CommandRunner<void>('rekeens', 'Rekeens CLI test runner');
      runner.addCommand(ConfigCommand());
      expect(() => runner.run(['config']), throwsA(isA<UsageException>()));
    });
  });
}
