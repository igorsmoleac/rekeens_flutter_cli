import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/template_service.dart';

void main() {
  late Directory tempDir;
  late TemplateService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('template_test_');
    service = const TemplateService();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'copyTemplate replaces placeholders in file content and names',
    () async {
      final source = Directory(p.join(tempDir.path, 'source'))..createSync();
      final target = Directory(p.join(tempDir.path, 'target'))..createSync();

      File(p.join(source.path, '{{name}}_file.txt'))
          .writeAsStringSync('Hello {{name}}!');

      await service.copyTemplate(
        sourceDir: source.path,
        targetDir: target.path,
        variables: {'name': 'world'},
      );

      final copiedFile = File(p.join(target.path, 'world_file.txt'));
      expect(copiedFile.existsSync(), isTrue);
      expect(copiedFile.readAsStringSync(), 'Hello world!');
    },
  );

  test('copyTemplate creates directories', () async {
    final source = Directory(p.join(tempDir.path, 'source'))..createSync();
    final target = Directory(p.join(tempDir.path, 'target'))..createSync();

    Directory(p.join(source.path, 'nested')).createSync();
    File(p.join(source.path, 'nested', 'test.txt')).writeAsStringSync('data');

    await service.copyTemplate(
      sourceDir: source.path,
      targetDir: target.path,
      variables: {},
    );

    expect(Directory(p.join(target.path, 'nested')).existsSync(), isTrue);
    expect(
      File(p.join(target.path, 'nested', 'test.txt')).existsSync(),
      isTrue,
    );
  });

  test('throws when source directory does not exist', () {
    expect(
      () => service.copyTemplate(
        sourceDir: p.join(tempDir.path, 'nonexistent'),
        targetDir: p.join(tempDir.path, 'target'),
        variables: {},
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('creates target directory if it does not exist', () async {
    final source = Directory(p.join(tempDir.path, 'source'))..createSync();
    File(p.join(source.path, 'file.txt')).writeAsStringSync('content');

    await service.copyTemplate(
      sourceDir: source.path,
      targetDir: p.join(tempDir.path, 'new_target'),
      variables: {},
    );

    expect(
      File(p.join(tempDir.path, 'new_target', 'file.txt')).existsSync(),
      isTrue,
    );
  });

  test('replaces multiple different variables', () async {
    final source = Directory(p.join(tempDir.path, 'source'))..createSync();
    final target = Directory(p.join(tempDir.path, 'target'))..createSync();

    File(p.join(source.path, 'file.txt'))
        .writeAsStringSync('{{name}} is {{age}} years old');

    await service.copyTemplate(
      sourceDir: source.path,
      targetDir: target.path,
      variables: {'name': 'Alice', 'age': '30'},
    );

    expect(
      File(p.join(target.path, 'file.txt')).readAsStringSync(),
      'Alice is 30 years old',
    );
  });

  test('replaces placeholders in directory names', () async {
    final source = Directory(p.join(tempDir.path, 'source'))..createSync();
    final target = Directory(p.join(tempDir.path, 'target'))..createSync();

    Directory(p.join(source.path, '{{feature}}')).createSync();
    File(p.join(source.path, '{{feature}}', 'file.dart'))
        .writeAsStringSync('class {{feature}} {}');

    await service.copyTemplate(
      sourceDir: source.path,
      targetDir: target.path,
      variables: {'feature': 'auth'},
    );

    expect(Directory(p.join(target.path, 'auth')).existsSync(), isTrue);
    expect(
      File(p.join(target.path, 'auth', 'file.dart')).readAsStringSync(),
      'class auth {}',
    );
  });

  test('copies binary files without modification', () async {
    final source = Directory(p.join(tempDir.path, 'source'))..createSync();
    final target = Directory(p.join(tempDir.path, 'target'))..createSync();

    final binaryData = List<int>.generate(256, (i) => i);
    File(p.join(source.path, 'image.png')).writeAsBytesSync(binaryData);

    await service.copyTemplate(
      sourceDir: source.path,
      targetDir: target.path,
      variables: {'name': 'test'},
    );

    final copied = File(p.join(target.path, 'image.png'));
    expect(copied.existsSync(), isTrue);
    expect(copied.readAsBytesSync(), binaryData);
  });

  test('handles deeply nested directory structures', () async {
    final source = Directory(p.join(tempDir.path, 'source'))..createSync();
    final target = Directory(p.join(tempDir.path, 'target'))..createSync();

    Directory(p.join(source.path, 'a', 'b', 'c', 'd'))
        .createSync(recursive: true);
    File(p.join(source.path, 'a', 'b', 'c', 'd', 'deep.txt'))
        .writeAsStringSync('deep content');

    await service.copyTemplate(
      sourceDir: source.path,
      targetDir: target.path,
      variables: {},
    );

    expect(
      File(p.join(target.path, 'a', 'b', 'c', 'd', 'deep.txt')).existsSync(),
      isTrue,
    );
  });

  test('copies .gitkeep files as text', () async {
    final source = Directory(p.join(tempDir.path, 'source'))..createSync();
    final target = Directory(p.join(tempDir.path, 'target'))..createSync();

    File(p.join(source.path, '.gitkeep')).writeAsStringSync('');

    await service.copyTemplate(
      sourceDir: source.path,
      targetDir: target.path,
      variables: {},
    );

    expect(File(p.join(target.path, '.gitkeep')).existsSync(), isTrue);
  });

  test('handles empty variables map', () async {
    final source = Directory(p.join(tempDir.path, 'source'))..createSync();
    final target = Directory(p.join(tempDir.path, 'target'))..createSync();

    File(p.join(source.path, 'file.txt')).writeAsStringSync('no placeholders');

    await service.copyTemplate(
      sourceDir: source.path,
      targetDir: target.path,
      variables: {},
    );

    expect(
      File(p.join(target.path, 'file.txt')).readAsStringSync(),
      'no placeholders',
    );
  });

  test('leaves unreplaced placeholders when no matching variable', () async {
    final source = Directory(p.join(tempDir.path, 'source'))..createSync();
    final target = Directory(p.join(tempDir.path, 'target'))..createSync();

    File(p.join(source.path, 'file.txt'))
        .writeAsStringSync('Hello {{name}} and {{other}}!');

    await service.copyTemplate(
      sourceDir: source.path,
      targetDir: target.path,
      variables: {'name': 'world'},
    );

    expect(
      File(p.join(target.path, 'file.txt')).readAsStringSync(),
      'Hello world and {{other}}!',
    );
  });

  test('handles source with only directories and no files', () async {
    final source = Directory(p.join(tempDir.path, 'source'))..createSync();
    final target = Directory(p.join(tempDir.path, 'target'))..createSync();

    Directory(p.join(source.path, 'empty_dir')).createSync();

    await service.copyTemplate(
      sourceDir: source.path,
      targetDir: target.path,
      variables: {},
    );

    expect(Directory(p.join(target.path, 'empty_dir')).existsSync(), isTrue);
  });
}
