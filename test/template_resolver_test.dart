import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/utils/template_resolver.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempRoot;
  late Directory fakePackageRoot;
  late Directory workingDir;
  late Directory fakeHome;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('tpl_resolver_test_');
    fakePackageRoot = Directory(p.join(tempRoot.path, 'pkg'))..createSync();
    workingDir = Directory(p.join(tempRoot.path, 'project'))..createSync();
    fakeHome = Directory(p.join(tempRoot.path, 'home'))..createSync();
  });

  tearDown(() {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  Directory builtIn(String category, [String? sub]) {
    final dir = Directory(
      p.joinAll([fakePackageRoot.path, 'templates', category, ?sub]),
    )..createSync(recursive: true);
    File(p.join(dir.path, 'built_in.txt')).writeAsStringSync('builtin');
    return dir;
  }

  Directory local(String category, [String? sub]) {
    final dir = Directory(
      p.joinAll([workingDir.path, '.rekeens', 'templates', category, ?sub]),
    )..createSync(recursive: true);
    File(p.join(dir.path, 'local.txt')).writeAsStringSync('local');
    return dir;
  }

  Directory home(String category, [String? sub]) {
    final dir = Directory(
      p.joinAll([fakeHome.path, '.rekeens', 'templates', category, ?sub]),
    )..createSync(recursive: true);
    File(p.join(dir.path, 'home.txt')).writeAsStringSync('home');
    return dir;
  }

  test(
    'falls back to built-in templates when no user/local templates exist',
    () async {
      final b = builtIn('features', 'feature');
      final resolver = TemplateResolver(homeDirectoryOverride: fakeHome.path);

      final resolved = await resolver.resolve(
        category: 'features',
        subPath: 'feature',
        workingDirectory: workingDir.path,
        packageRootOverride: fakePackageRoot.path,
      );

      expect(resolved, b.path);
      expect(File(p.join(resolved, 'built_in.txt')).existsSync(), isTrue);
    },
  );

  test('prefers local project templates over built-in', () async {
    builtIn('features', 'feature');
    final l = local('features', 'feature');
    final resolver = TemplateResolver(homeDirectoryOverride: fakeHome.path);

    final resolved = await resolver.resolve(
      category: 'features',
      subPath: 'feature',
      workingDirectory: workingDir.path,
      packageRootOverride: fakePackageRoot.path,
    );

    expect(resolved, l.path);
    expect(File(p.join(resolved, 'local.txt')).existsSync(), isTrue);
    expect(File(p.join(resolved, 'built_in.txt')).existsSync(), isFalse);
  });

  test('prefers home templates over local and built-in', () async {
    final h = home('features', 'feature');
    local('features', 'feature');
    builtIn('features', 'feature');
    final resolver = TemplateResolver(homeDirectoryOverride: fakeHome.path);

    final resolved = await resolver.resolve(
      category: 'features',
      subPath: 'feature',
      workingDirectory: workingDir.path,
      packageRootOverride: fakePackageRoot.path,
    );

    expect(resolved, h.path);
    expect(File(p.join(resolved, 'home.txt')).existsSync(), isTrue);
    expect(File(p.join(resolved, 'local.txt')).existsSync(), isFalse);
    expect(File(p.join(resolved, 'built_in.txt')).existsSync(), isFalse);
  });

  test('throws StateError when template not found anywhere', () async {
    final resolver = TemplateResolver(homeDirectoryOverride: fakeHome.path);

    expect(
      () => resolver.resolve(
        category: 'features',
        subPath: 'missing',
        workingDirectory: workingDir.path,
        packageRootOverride: fakePackageRoot.path,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('resolves base category without subPath', () async {
    final b = builtIn('base');
    final resolver = TemplateResolver(homeDirectoryOverride: fakeHome.path);

    final resolved = await resolver.resolve(
      category: 'base',
      workingDirectory: workingDir.path,
      packageRootOverride: fakePackageRoot.path,
    );

    expect(resolved, b.path);
  });
}
