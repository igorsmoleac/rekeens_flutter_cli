import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/utils/project_paths.dart';
import 'package:yaml/yaml.dart';

Future<String> getAppVersion() async {
  final root = await getPackageRoot();
  final pubspecFile = File(p.join(root, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) return 'unknown';

  try {
    final content = pubspecFile.readAsStringSync();
    final yaml = loadYaml(content);
    if (yaml is Map && yaml['version'] != null) {
      return yaml['version'].toString();
    }
  } catch (_) {}

  return 'unknown';
}
