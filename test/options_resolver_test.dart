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
      expect(options['storage'], 'none');
      expect(options['localization'], isFalse);
      expect(options['theme'], 'material3');
      expect(options['seed_color'], '0xFF2196F3');
      expect(options['font_family'], '');
      expect(options['codegen'], isFalse);
      expect(options['pin_versions'], isFalse);
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

    test('throws UsageException for invalid flag overriding preset', () async {
      await expectUsageException([
        '--preset=minimal',
        '--state-management=Riverpod',
      ]);
    });
  });

  group('OptionsResolver.resolve — enum flag validation', () {
    test('throws UsageException for invalid state-management', () async {
      await expectUsageException(['--state-management=Riverpod']);
    });

    test('throws UsageException for invalid router', () async {
      await expectUsageException(['--router=auto_router']);
    });

    test('throws UsageException for invalid networking', () async {
      await expectUsageException(['--networking=retrofit']);
    });

    test('throws UsageException for invalid storage', () async {
      await expectUsageException(['--storage=hive']);
    });

    test('throws UsageException for invalid theme', () async {
      await expectUsageException(['--theme=cupertino']);
    });

    test('throws UsageException for invalid seed-color (too short)', () async {
      await expectUsageException(['--seed-color=123']);
    });

    test('throws UsageException for invalid seed-color (non-hex)', () async {
      await expectUsageException(['--seed-color=ZZZZZZ']);
    });

    test('throws UsageException for unsupported architecture', () async {
      await expectUsageException(['--architecture=clean-architecture']);
    });

    test('accepts all valid state-management values', () async {
      for (final value in ['riverpod', 'bloc', 'none']) {
        final options = await resolve(['--state-management=$value']);
        expect(options['state_management'], value);
      }
    });

    test('accepts all valid networking values', () async {
      for (final value in ['dio', 'http', 'none']) {
        final options = await resolve(['--networking=$value']);
        expect(options['networking'], value);
      }
    });

    test('accepts all valid storage values', () async {
      for (final value in ['shared_preferences', 'secure_storage', 'none']) {
        final options = await resolve(['--storage=$value']);
        expect(options['storage'], value);
      }
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
      expect(options['storage'], 'shared_preferences');
      expect(options['localization'], isFalse);
      expect(options['theme'], 'material3');
      expect(options['seed_color'], '0xFF2196F3');
      expect(options['font_family'], '');
      expect(options['codegen'], isFalse);
      expect(options['pin_versions'], isFalse);
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
        '--storage=secure_storage',
        '--theme=material2',
        '--seed-color=#FF5722',
        '--font-family=Inter',
        '--codegen',
        '--localization',
      ]);
      expect(options['architecture'], 'feature-first');
      expect(options['state_management'], 'none');
      expect(options['router'], 'none');
      expect(options['networking'], 'http');
      expect(options['storage'], 'secure_storage');
      expect(options['theme'], 'material2');
      expect(options['seed_color'], '0xFFFF5722');
      expect(options['font_family'], 'Inter');
      expect(options['codegen'], isTrue);
      expect(options['localization'], isTrue);
    });

    test('normalizes 6-digit hex seed-color', () async {
      final options = await resolve(['--seed-color=2196F3']);
      expect(options['seed_color'], '0xFF2196F3');
    });

    test('normalizes # prefixed seed-color', () async {
      final options = await resolve(['--seed-color=#2196F3']);
      expect(options['seed_color'], '0xFF2196F3');
    });

    test('accepts 8-digit hex seed-color with alpha', () async {
      final options = await resolve(['--seed-color=0xFFFF5722']);
      expect(options['seed_color'], '0xFFFF5722');
    });

    test('empty font-family flag defaults to empty string', () async {
      final options = await resolve(['--font-family=']);
      expect(options['font_family'], '');
    });

    test('pin-versions flag sets pin_versions to true', () async {
      final options = await resolve(['--pin-versions']);
      expect(options['pin_versions'], isTrue);
    });

    test('no-pin-versions flag sets pin_versions to false', () async {
      final options = await resolve(['--no-pin-versions']);
      expect(options['pin_versions'], isFalse);
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
  storage: secure_storage
''');
      final options = await resolve(<String>[]);
      expect(options['state_management'], 'bloc');
      expect(options['router'], 'none');
      expect(options['theme'], 'material2');
      expect(options['localization'], isTrue);
      expect(options['codegen'], isTrue);
      expect(options['platforms'], ['android', 'web']);
      expect(options['networking'], 'http');
      expect(options['storage'], 'secure_storage');
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

    test(
      'throws UsageException for invalid state_management in config',
      () async {
        File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: Riverpod
  router: go_router
  theme: material3
  localization: false
  codegen: false
  platforms:
    - android
  architecture: feature-first
  networking: dio
''');
        await expectUsageException(<String>[]);
      },
    );

    test('throws UsageException for invalid theme in config', () async {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: riverpod
  router: go_router
  theme: cupertino
  localization: false
  codegen: false
  platforms:
    - android
  architecture: feature-first
  networking: dio
''');
      await expectUsageException(<String>[]);
    });

    test(
      'throws UsageException for unsupported architecture in config',
      () async {
        File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: riverpod
  router: go_router
  theme: material3
  localization: false
  codegen: false
  platforms:
    - android
  architecture: clean-architecture
  networking: dio
''');
        await expectUsageException(<String>[]);
      },
    );
  });

  group('OptionsResolver.resolve — interactive prompt', () {
    test('collects options from prompt when nothing else is given', () async {
      // Inputs in order: platforms (multi, comma), architecture, state, router,
      // networking, storage, codegen (y/n), pin_versions (y/n),
      // localization (y/n), theme, seed_color, font_family.
      inputs = [
        '1,2', // platforms -> android, ios
        '', // architecture default
        '', // state default
        '', // router default
        '', // networking default
        '', // storage default
        'n', // codegen
        'n', // pin_versions
        'n', // localization
        '', // theme default
        '', // seed_color default
        '', // font_family default
      ];
      final options = await resolve(<String>[]);
      expect(options['platforms'], ['android', 'ios']);
      expect(options['architecture'], 'feature-first');
      expect(options['state_management'], 'riverpod');
      expect(options['router'], 'go_router');
      expect(options['networking'], 'dio');
      expect(options['storage'], 'shared_preferences');
      expect(options['codegen'], isFalse);
      expect(options['pin_versions'], isFalse);
      expect(options['localization'], isFalse);
      expect(options['theme'], 'material3');
      expect(options['seed_color'], '0xFF2196F3');
      expect(options['font_family'], '');
    });
  });

  group('OptionsResolver.resolve — analysis_options from config', () {
    test('includes analysis_options when config has the section', () async {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: riverpod
  router: go_router
  theme: material3
  localization: false
  codegen: false
  platforms:
    - android
  architecture: feature-first
  networking: dio
  storage: shared_preferences
analysis_options:
  include: package:flutter_lints/flutter.yaml
  linter:
    rules:
      prefer_const_constructors: true
''');
      final options = await resolve(<String>[]);
      expect(options.containsKey('analysis_options'), isTrue);
      final ao = options['analysis_options'] as Map<String, dynamic>;
      expect(ao['include'], 'package:flutter_lints/flutter.yaml');
      expect(ao['linter'], isA<Map>());
    });

    test(
      'does not include analysis_options when config lacks the section',
      () async {
        File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: riverpod
  router: go_router
  theme: material3
  localization: false
  codegen: false
  platforms:
    - android
  architecture: feature-first
  networking: dio
  storage: shared_preferences
''');
        final options = await resolve(<String>[]);
        expect(options.containsKey('analysis_options'), isFalse);
      },
    );

    test('includes analysis_options even when using --preset', () async {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: riverpod
analysis_options:
  include: package:lints/recommended.yaml
''');
      final options = await resolve(['--preset=minimal']);
      expect(options.containsKey('analysis_options'), isTrue);
      expect(
        (options['analysis_options'] as Map<String, dynamic>)['include'],
        'package:lints/recommended.yaml',
      );
    });

    test(
      'does not include analysis_options when no config file exists',
      () async {
        final options = await resolve(['--state-management=bloc']);
        expect(options.containsKey('analysis_options'), isFalse);
      },
    );
  });
}
