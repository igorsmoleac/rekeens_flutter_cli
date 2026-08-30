import 'dart:io';

String? readPackageName(File pubspecFile) {
  if (!pubspecFile.existsSync()) return null;
  try {
    final lines = pubspecFile.readAsLinesSync();
    for (final line in lines) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final trimmed = line.trimLeft();
      if (!trimmed.startsWith('name:')) continue;
      final value = trimmed.substring(5).trim();
      if (value.isEmpty) return null;
      return value;
    }
  } catch (_) {}
  return null;
}
