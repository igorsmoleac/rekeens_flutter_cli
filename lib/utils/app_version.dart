import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/utils/logger.dart';
import 'package:rekeens_flutter_cli/utils/project_paths.dart';
import 'package:yaml/yaml.dart';

Future<String> getAppVersion() async {
  final String root;
  try {
    root = await getPackageRoot();
  } catch (e) {
    logger.warn('Could not resolve package root: $e');
    return 'unknown';
  }
  final pubspecFile = File(p.join(root, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) return 'unknown';

  try {
    final content = pubspecFile.readAsStringSync();
    final yaml = loadYaml(content);
    if (yaml is Map && yaml['version'] != null) {
      return yaml['version'].toString();
    }
  } catch (e) {
    logger.warn('Could not read app version from ${pubspecFile.path}: $e');
  }

  return 'unknown';
}
