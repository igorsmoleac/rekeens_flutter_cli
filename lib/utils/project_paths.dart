import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/utils/package_metadata.dart';

Future<String> getPackageRoot() async {
  final resolved = await Isolate.resolvePackageUri(
    Uri.parse('package:rekeens_flutter_cli/utils/project_paths.dart'),
  );
  if (resolved != null && resolved.scheme == 'file') {
    final file = File.fromUri(resolved);
    if (file.existsSync()) {
      final libDir = p.dirname(file.path);
      final root = p.dirname(libDir);
      if (_isPackageRoot(root)) return root;
    }
  }

  final fromScript = _findRootFromPath(Platform.script.toFilePath());
  if (fromScript != null) return fromScript;

  final fromExecutable = _findRootFromPath(Platform.resolvedExecutable);
  if (fromExecutable != null) return fromExecutable;

  throw StateError('Unable to locate rekeens_flutter_cli package root.');
}

String? _findRootFromPath(String startPath) {
  var dir = FileSystemEntity.typeSync(startPath) == FileSystemEntityType.file
      ? p.dirname(startPath)
      : startPath;
  while (true) {
    if (_isPackageRoot(dir)) return dir;
    final parent = p.dirname(dir);
    if (parent == dir) return null;
    dir = parent;
  }
}

bool _isPackageRoot(String dir) {
  final pubspecFile = File(p.join(dir, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) return false;
  return readPackageName(pubspecFile) == 'rekeens_flutter_cli';
}
