import 'dart:io';

class TemplateService {
  const TemplateService();

  Future<void> copyTemplate({
    required String sourceDir,
    required String targetDir,
    required Map<String, String> variables,
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
        relativePath = relativePath.replaceAll('{{${key}}}', value);
      });

      final targetPath = '${targetDir}${Platform.pathSeparator}$relativePath';

      if (entity is Directory) {
        Directory(targetPath).createSync(recursive: true);
      } else if (entity is File) {
        final file = entity;
        if (_isTextFile(file.path)) {
          var content = await file.readAsString();
          variables.forEach((key, value) {
            content = content.replaceAll('{{${key}}}', value);
          });
          await File(targetPath).writeAsString(content);
        } else {
          await file.copy(targetPath);
        }
      }
    }
  }

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
