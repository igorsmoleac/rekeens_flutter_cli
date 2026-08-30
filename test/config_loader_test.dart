import 'dart:io';

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
