import 'dart:io';

class TemplateService {
  const TemplateService();

  Future<void> copyTemplate({
    required String sourceDir,
    required String targetDir,
    required Map<String, String> variables,
    Map<String, bool>? conditions,
  }) async {
    final source = Directory(sourceDir);
    if (!source.existsSync()) {
      throw Exception('Template directory not found: $sourceDir');
    }

    final target = Directory(targetDir);
    if (!target.existsSync()) {
      target.createSync(recursive: true);
    }

    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
      var relativePath = entity.path.substring(sourceDir.length + 1);

      variables.forEach((key, value) {
        relativePath = relativePath.replaceAll('{{$key}}', value);
      });

      final targetPath = '$targetDir${Platform.pathSeparator}$relativePath';

      if (entity is Directory) {
        Directory(targetPath).createSync(recursive: true);
      } else if (entity is File) {
        final file = entity;
        if (_isTextFile(file.path)) {
          var content = await file.readAsString();
          content = renderContent(content, variables, conditions: conditions);
          await File(targetPath).writeAsString(content);
        } else {
          await file.copy(targetPath);
        }
      }
    }
  }

  Future<void> renderFile({
    required String sourcePath,
    required String targetPath,
    required Map<String, String> variables,
    Map<String, bool>? conditions,
  }) async {
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      throw Exception('Template file not found: $sourcePath');
    }

    var content = await sourceFile.readAsString();
    content = renderContent(content, variables, conditions: conditions);

    final targetFile = File(targetPath);
    final targetParent = targetFile.parent;
    if (!targetParent.existsSync()) {
      targetParent.createSync(recursive: true);
    }
    await targetFile.writeAsString(content);
  }

  String renderContent(
    String content,
    Map<String, String> variables, {
    Map<String, bool>? conditions,
  }) {
    var result = _processConditionals(content, conditions ?? const {});
    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }

  String _processConditionals(String content, Map<String, bool> conditions) {
    var result = content;
    while (true) {
      final match = _conditionalRegex.firstMatch(result);
      if (match == null) break;

      final type = match.group(1)!;
      final cond = match.group(2)!;
      final inner = match.group(3)!;

      final condValue = conditions[cond] ?? false;
      final include = type == 'if' ? condValue : !condValue;

      result = result.replaceRange(
        match.start,
        match.end,
        include ? inner : '',
      );
    }
    return result;
  }

  static final _conditionalRegex = RegExp(
    r'\{\{#(if|unless)\s+(\w+)\}\}((?:(?!\{\{#(?:if|unless)).)*?)\{\{/\1\}\}',
    dotAll: true,
  );

  bool _isTextFile(String path) {
    const textExtensions = [
      '.dart',
      '.yaml',
      '.yml',
      '.json',
      '.md',
      '.txt',
      '.gitignore',
      '.html',
      '.css',
      '.js',
      '.xml',
      '.plist',
      '.properties',
      '.lock',
      '.gradle',
      '.kts',
      '.pbxproj',
      '.xcconfig',
      '.entitlements',
    ];
    final extension = path.contains('.')
        ? path.substring(path.lastIndexOf('.'))
        : '';
    return textExtensions.contains(extension.toLowerCase());
  }
}
