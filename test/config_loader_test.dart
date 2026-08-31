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
