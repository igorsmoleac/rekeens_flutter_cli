import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class ConfigLoader {
  static Map<String, dynamic>? load() {
    final configFile = _findConfigFile();
    if (configFile == null) return null;

    try {
      final content = File(configFile).readAsStringSync();
      final yamlMap = loadYaml(content);
      if (yamlMap is! Map) return null;

      final defaults = yamlMap['defaults'];
      if (defaults is YamlMap) {
        return _convertYamlMap(defaults);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String? _findConfigFile() {
    final currentDir = Directory.current.path;
    final localConfig = p.join(currentDir, 'rekeens.yaml');
    if (File(localConfig).existsSync()) {
      return localConfig;
    }

    final home =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    if (home != null) {
      final homeConfig = p.join(home, 'rekeens.yaml');
      if (File(homeConfig).existsSync()) {
        return homeConfig;
      }
    }

    return null;
  }

  static Map<String, dynamic> _convertYamlMap(YamlMap map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is YamlList) {
        result[key] = value.map((e) => e.toString()).toList();
      } else {
        result[key] = value;
      }
    }
    return result;
  }
}
