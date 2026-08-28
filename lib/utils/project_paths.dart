import 'dart:io';

import 'package:path/path.dart' as p;

String getPackageRoot() {
  final scriptPath = Platform.script.toFilePath();
  var dir = p.dirname(scriptPath);

  while (!File(p.join(dir, 'pubspec.yaml')).existsSync()) {
    final parent = p.dirname(dir);
    if (parent == dir) break;
    dir = parent;
  }

  return dir;
}
