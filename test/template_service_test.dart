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
}
