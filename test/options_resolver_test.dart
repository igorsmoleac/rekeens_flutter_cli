import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/commands/create_command.dart';
import 'package:rekeens_flutter_cli/services/options_resolver.dart';
import 'package:rekeens_flutter_cli/services/prompter_service.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late StringBuffer output;
  late List<String> inputs;
  late int inputIndex;
  late PrompterService prompter;
  late OptionsResolver resolver;
  late CreateCommand command;

  PrompterService makePrompter() {
    return PrompterService(
      output: output,
      readLine: () {
        if (inputIndex < inputs.length) {
          return inputs[inputIndex++];
        }
        return null;
      },
    );
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('options_resolver_test_');
    output = StringBuffer();
    inputs = [];
    inputIndex = 0;
    prompter = makePrompter();
    // Point the resolver at an empty temp dir (no rekeens.yaml) instead of
    // mutating the global Directory.current, which would break parallel tests.
    resolver = OptionsResolver(
      prompter: prompter,
      workingDirectory: tempDir.path,
      homeDirectory: tempDir.path,
    );
    command = CreateCommand(optionsResolver: resolver);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<Map<String, dynamic>> resolve(List<String> args) async {
    final argResults = command.argParser.parse(['my_app', ...args]);
    return resolver.resolve(argResults, usage: 'test usage');
  }

  Future<void> expectUsageException(List<String> args) async {
    final argResults = command.argParser.parse(['my_app', ...args]);
    expect(
      () => resolver.resolve(argResults, usage: 'test usage'),
      throwsA(isA<UsageException>()),
    );
  }

  group('OptionsResolver.resolve — preset', () {
    test('returns preset options when --preset is given', () async {
      final options = await resolve(['--preset=minimal']);
      expect(options['platforms'], ['android', 'ios']);
      expect(options['state_management'], 'none');
      expect(options['router'], 'none');
      expect(options['networking'], 'none');
      expect(options['localization'], isFalse);
      expect(options['theme'], 'material3');
      expect(options['codegen'], isFalse);
    });

    test('flag overrides preset value', () async {
      final options = await resolve([
        '--preset=minimal',
        '--state-management=bloc',
        '--router=go_router',
      ]);
      expect(options['state_management'], 'bloc');
      expect(options['router'], 'go_router');
      expect(options['platforms'], ['android', 'ios']);
    });

    test('throws UsageException for unknown preset', () async {
      await expectUsageException(['--preset=nonexistent']);
    });

    test('full preset enables codegen', () async {
      final options = await resolve(['--preset=full']);
      expect(options['codegen'], isTrue);
      expect(options['platforms'], [
        'android',
        'ios',
        'windows',
        'linux',
        'macos',
        'web',
      ]);
    });
  });

  group('OptionsResolver.resolve — flags only', () {
    test('fills defaults for unspecified options', () async {
      final options = await resolve(['--state-management=bloc']);
      expect(options['state_management'], 'bloc');
      expect(options['platforms'], ['android', 'ios', 'windows', 'linux']);
      expect(options['architecture'], 'feature-first');
      expect(options['router'], 'go_router');
      expect(options['networking'], 'dio');
      expect(options['localization'], isFalse);
      expect(options['theme'], 'material3');
      expect(options['codegen'], isFalse);
    });

    test('parses comma-separated platforms', () async {
      final options = await resolve(['--platforms=android,ios,web']);
      expect(options['platforms'], ['android', 'ios', 'web']);
    });

    test('trims and filters empty platform entries', () async {
      final options = await resolve(['--platforms= android , , ios ']);
      expect(options['platforms'], ['android', 'ios']);
    });

    test('empty platforms string yields empty list', () async {
      final options = await resolve(['--platforms=']);
      expect(options['platforms'], <String>[]);
    });

    test('reads all single-value flags', () async {
      final options = await resolve([
        '--architecture=feature-first',
        '--state-management=none',
        '--router=none',
        '--networking=http',
        '--theme=material2',
        '--codegen',
        '--localization',
      ]);
      expect(options['architecture'], 'feature-first');
      expect(options['state_management'], 'none');
      expect(options['router'], 'none');
      expect(options['networking'], 'http');
      expect(options['theme'], 'material2');
      expect(options['codegen'], isTrue);
      expect(options['localization'], isTrue);
    });
  });

  group('OptionsResolver.resolve — config file', () {
    test('uses rekeens.yaml defaults when no flags and no preset', () async {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: bloc
  router: none
  theme: material2
  localization: true
  codegen: true
  platforms:
    - android
    - web
  architecture: feature-first
  networking: http
''');
      final options = await resolve(<String>[]);
      expect(options['state_management'], 'bloc');
      expect(options['router'], 'none');
      expect(options['theme'], 'material2');
      expect(options['localization'], isTrue);
      expect(options['codegen'], isTrue);
      expect(options['platforms'], ['android', 'web']);
      expect(options['networking'], 'http');
    });

    test('flags override config file values', () async {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: bloc
  router: none
  theme: material2
  localization: false
  codegen: false
  platforms:
    - android
  architecture: feature-first
  networking: http
''');
      final options = await resolve(['--state-management=riverpod']);
      expect(options['state_management'], 'riverpod');
      // From config
      expect(options['router'], 'none');
      expect(options['theme'], 'material2');
    });
  });

  group('OptionsResolver.resolve — interactive prompt', () {
    test('collects options from prompt when nothing else is given', () async {
      // Inputs in order: platforms (multi, comma), architecture, state, router,
      // networking, codegen (y/n), localization (y/n), theme.
      inputs = [
        '1,2', // platforms -> android, ios
        '', // architecture default
        '', // state default
        '', // router default
        '', // networking default
        'n', // codegen
        'n', // localization
        '', // theme default
      ];
      final options = await resolve(<String>[]);
      expect(options['platforms'], ['android', 'ios']);
      expect(options['architecture'], 'feature-first');
      expect(options['state_management'], 'riverpod');
      expect(options['router'], 'go_router');
      expect(options['networking'], 'dio');
      expect(options['codegen'], isFalse);
      expect(options['localization'], isFalse);
      expect(options['theme'], 'material3');
    });
  });
}
