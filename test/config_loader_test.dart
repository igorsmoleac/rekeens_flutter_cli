import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/config/config_loader.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late Directory fakeHome;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('config_loader_test_');
    fakeHome = Directory.systemTemp.createTempSync('config_loader_home_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    if (fakeHome.existsSync()) fakeHome.deleteSync(recursive: true);
  });

  Future<String> captureOutput(Future<void> Function() body) async {
    final bytes = <int>[];
    await IOOverrides.runZoned(
      () async => await body(),
      stdout: () => _MemoryStdout(bytes),
      stderr: () => _MemoryStdout(bytes),
    );
    return utf8.decode(bytes);
  }

  group('ConfigLoader.load', () {
    test('returns null when no config file exists', () {
      final result = ConfigLoader.load(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );
      expect(result, isNull);
    });

    test('loads defaults from local rekeens.yaml', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: riverpod
  router: go_router
  theme: material3
  localization: true
''');

      final result = ConfigLoader.load(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result, isNotNull);
      expect(result!['state_management'], 'riverpod');
      expect(result['router'], 'go_router');
      expect(result['theme'], 'material3');
      expect(result['localization'], isTrue);
    });

    test('loads defaults from home rekeens.yaml when local is absent', () {
      File(p.join(fakeHome.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: bloc
  router: none
''');

      final result = ConfigLoader.load(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result, isNotNull);
      expect(result!['state_management'], 'bloc');
      expect(result['router'], 'none');
    });

    test('local config takes precedence over home config', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: riverpod
''');
      File(p.join(fakeHome.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: bloc
''');

      final result = ConfigLoader.load(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result, isNotNull);
      expect(result!['state_management'], 'riverpod');
    });

    test('returns null when YAML has no defaults section', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
some_other_key: value
''');

      final result = ConfigLoader.load(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result, isNull);
    });

    test('returns null when YAML is invalid', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
: : : invalid yaml :::
''');

      final result = ConfigLoader.load(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result, isNull);
    });

    test('logs a warning when YAML is invalid', () async {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
not: [valid: yaml
''');
      final log = Logger(level: Level.verbose);

      final output = await captureOutput(() async {
        ConfigLoader.load(
          workingDirectory: tempDir.path,
          homeDirectory: fakeHome.path,
          log: log,
        );
      });

      expect(output, contains('Failed to parse rekeens.yaml'));
      expect(output, contains('flow sequence'));
      expect(output, contains('falling back to defaults'));
    });

    test('warning includes the resolved config file path', () async {
      final configPath = p.join(tempDir.path, 'rekeens.yaml');
      File(configPath).writeAsStringSync('not: [valid: yaml');
      final log = Logger(level: Level.verbose);

      final output = await captureOutput(() async {
        ConfigLoader.load(
          workingDirectory: tempDir.path,
          homeDirectory: fakeHome.path,
          log: log,
        );
      });

      expect(output, contains(configPath));
    });

    test('does not warn when config file is absent', () async {
      final log = Logger(level: Level.verbose);

      final output = await captureOutput(() async {
        ConfigLoader.load(
          workingDirectory: tempDir.path,
          homeDirectory: fakeHome.path,
          log: log,
        );
      });

      expect(output, '');
    });

    test(
      'does not warn when YAML is valid but has no defaults section',
      () async {
        File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
some_other_key: value
''');
        final log = Logger(level: Level.verbose);

        final output = await captureOutput(() async {
          ConfigLoader.load(
            workingDirectory: tempDir.path,
            homeDirectory: fakeHome.path,
            log: log,
          );
        });

        expect(output, '');
      },
    );

    test('returns null when config file is empty', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('');

      final result = ConfigLoader.load(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result, isNull);
    });

    test('converts YAML lists to List<String>', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  platforms:
    - android
    - ios
    - web
''');

      final result = ConfigLoader.load(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result, isNotNull);
      final platforms = result!['platforms'] as List;
      expect(platforms, ['android', 'ios', 'web']);
      expect(platforms.first, isA<String>());
    });

    test('handles boolean values in defaults', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  localization: false
  codegen: true
''');

      final result = ConfigLoader.load(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result, isNotNull);
      expect(result!['localization'], isFalse);
      expect(result['codegen'], isTrue);
    });

    test('handles null homeDirectory gracefully', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  theme: material2
''');

      final result = ConfigLoader.load(
        workingDirectory: tempDir.path,
        homeDirectory: null,
      );

      expect(result, isNotNull);
      expect(result!['theme'], 'material2');
    });

    test('returns null when homeDirectory is null and no local config', () {
      final result = ConfigLoader.load(
        workingDirectory: tempDir.path,
        homeDirectory: null,
      );

      expect(result, isNull);
    });
  });

  group('ConfigLoader.loadAnalysisOptions', () {
    test('returns analysis_options section as nested map', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: riverpod
analysis_options:
  include: package:flutter_lints/flutter.yaml
  analyzer:
    language:
      strict-casts: true
      strict-raw-types: true
  linter:
    rules:
      prefer_const_constructors: true
      avoid_print: false
''');

      final result = ConfigLoader.loadAnalysisOptions(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result, isNotNull);
      expect(result!['include'], 'package:flutter_lints/flutter.yaml');
      expect(result['analyzer'], isA<Map>());
      final analyzer = result['analyzer'] as Map;
      expect(analyzer['language'], isA<Map>());
      final language = analyzer['language'] as Map;
      expect(language['strict-casts'], true);
      expect(language['strict-raw-types'], true);
      expect(result['linter'], isA<Map>());
      final linter = result['linter'] as Map;
      expect(linter['rules'], isA<Map>());
      final rules = linter['rules'] as Map;
      expect(rules['prefer_const_constructors'], true);
      expect(rules['avoid_print'], false);
    });

    test('returns null when analysis_options section is absent', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: riverpod
''');

      final result = ConfigLoader.loadAnalysisOptions(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result, isNull);
    });

    test('returns null when no config file exists', () {
      final result = ConfigLoader.loadAnalysisOptions(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result, isNull);
    });

    test('returns null when analysis_options is not a map', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: riverpod
analysis_options: not-a-map
''');

      final result = ConfigLoader.loadAnalysisOptions(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result, isNull);
    });

    test('handles list values in linter rules', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: riverpod
analysis_options:
  include: package:lints/recommended.yaml
  linter:
    rules:
      - prefer_const_constructors
      - avoid_print
''');

      final result = ConfigLoader.loadAnalysisOptions(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result, isNotNull);
      final linter = result!['linter'] as Map;
      final rules = linter['rules'] as List;
      expect(rules, ['prefer_const_constructors', 'avoid_print']);
    });

    test('returns null and warns when YAML is invalid', () async {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
: invalid: yaml: :
''');

      final output = await captureOutput(() async {
        ConfigLoader.loadAnalysisOptions(
          workingDirectory: tempDir.path,
          homeDirectory: fakeHome.path,
        );
      });

      expect(output, contains('Failed to parse analysis_options'));
    });

    test('loads from home config when local is absent', () {
      File(p.join(fakeHome.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: riverpod
analysis_options:
  include: package:lints/recommended.yaml
''');

      final result = ConfigLoader.loadAnalysisOptions(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result, isNotNull);
      expect(result!['include'], 'package:lints/recommended.yaml');
    });
  });

  group('ConfigLoader.loadHooks', () {
    test('returns empty HookSet when no config file exists', () {
      final result = ConfigLoader.loadHooks(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );
      expect(result.isEmpty, isTrue);
    });

    test('returns empty HookSet when config has no hooks section', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
defaults:
  state_management: riverpod
''');

      final result = ConfigLoader.loadHooks(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );
      expect(result.isEmpty, isTrue);
    });

    test('loads simple string hooks', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
hooks:
  before_generate:
    - echo "before"
  after_generate:
    - echo "after"
''');

      final result = ConfigLoader.loadHooks(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result.beforeGenerate.length, 1);
      expect(result.beforeGenerate[0].run, 'echo "before"');
      expect(result.beforeGenerate[0].when, isNull);
      expect(result.afterGenerate.length, 1);
      expect(result.afterGenerate[0].run, 'echo "after"');
    });

    test('loads map-style hooks with when and description', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
hooks:
  after_generate:
    - run: dart format lib/
      when: [model, entity]
      description: Format after generation
''');

      final result = ConfigLoader.loadHooks(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result.afterGenerate.length, 1);
      final hook = result.afterGenerate[0];
      expect(hook.run, 'dart format lib/');
      expect(hook.when, ['model', 'entity']);
      expect(hook.description, 'Format after generation');
    });

    test('loads multiple hooks', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
hooks:
  before_generate:
    - echo "first"
    - run: echo "second"
      when: [feature]
  after_generate:
    - echo "after1"
    - echo "after2"
''');

      final result = ConfigLoader.loadHooks(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result.beforeGenerate.length, 2);
      expect(result.beforeGenerate[0].run, 'echo "first"');
      expect(result.beforeGenerate[1].run, 'echo "second"');
      expect(result.beforeGenerate[1].when, ['feature']);
      expect(result.afterGenerate.length, 2);
    });

    test('skips entries without run field', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
hooks:
  after_generate:
    - description: missing run
    - run: echo "valid"
''');

      final result = ConfigLoader.loadHooks(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result.afterGenerate.length, 1);
      expect(result.afterGenerate[0].run, 'echo "valid"');
    });

    test('returns empty on malformed YAML', () {
      File(p.join(tempDir.path, 'rekeens.yaml')).writeAsStringSync('''
hooks: [invalid
''');

      final result = ConfigLoader.loadHooks(
        workingDirectory: tempDir.path,
        homeDirectory: fakeHome.path,
      );

      expect(result.isEmpty, isTrue);
    });
  });
}

class _MemoryStdout implements Stdout {
  _MemoryStdout(this._bytes);

  final List<int> _bytes;

  @override
  void write(object) {
    if (object is List<int>) {
      _bytes.addAll(object);
    } else {
      _bytes.addAll(utf8.encode('$object'));
    }
  }

  @override
  void writeln([object = '']) {
    write(object);
    _bytes.add(10);
  }

  @override
  bool get supportsAnsiEscapes => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
