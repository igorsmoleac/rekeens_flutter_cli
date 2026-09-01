import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/utils/logger.dart';
import 'package:yaml/yaml.dart';

class ConfigLoader {
  static Map<String, dynamic>? load({
    String? workingDirectory,
    String? homeDirectory,
    Logger? log,
  }) {
    final effectiveLog = log ?? logger;
    final configFile = _findConfigFile(
      workingDirectory: workingDirectory,
      homeDirectory: homeDirectory,
    );
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
    } catch (error) {
      effectiveLog.warn(
        'Failed to parse rekeens.yaml at "$configFile": $error. '
        'Ignoring config and falling back to defaults.',
      );
      return null;
    }
  }

  /// Loads the top-level `analysis_options` section from `rekeens.yaml`.
  ///
  /// Unlike [load] (which reads the `defaults` section), this returns the
  /// full nested structure as plain Dart maps/lists so it can be serialized
  /// back to `analysis_options.yaml` in the generated project.
  static Map<String, dynamic>? loadAnalysisOptions({
    String? workingDirectory,
    String? homeDirectory,
    Logger? log,
  }) {
    final effectiveLog = log ?? logger;
    final configFile = _findConfigFile(
      workingDirectory: workingDirectory,
      homeDirectory: homeDirectory,
    );
    if (configFile == null) return null;

    try {
      final content = File(configFile).readAsStringSync();
      final yamlMap = loadYaml(content);
      if (yamlMap is! Map) return null;

      final analysisOptions = yamlMap['analysis_options'];
      if (analysisOptions is YamlMap) {
        final converted = _convertYamlNode(analysisOptions);
        if (converted is Map<String, dynamic>) return converted;
      }
      return null;
    } catch (error) {
      effectiveLog.warn(
        'Failed to parse analysis_options in rekeens.yaml at "$configFile": '
        '$error. Ignoring analysis_options config.',
      );
      return null;
    }
  }

  static String? _findConfigFile({
    String? workingDirectory,
    String? homeDirectory,
  }) {
    final currentDir = workingDirectory ?? Directory.current.path;
    final localConfig = p.join(currentDir, 'rekeens.yaml');
    if (File(localConfig).existsSync()) {
      return localConfig;
    }

    final home =
        homeDirectory ??
        (Platform.environment['USERPROFILE'] ?? Platform.environment['HOME']);
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

  /// Recursively converts a [YamlMap] / [YamlList] / scalar into plain Dart
  /// types so the result can be serialized back to YAML by [YamlEditor].
  static dynamic _convertYamlNode(dynamic value) {
    if (value is YamlMap) {
      return <String, dynamic>{
        for (final entry in value.entries)
          entry.key.toString(): _convertYamlNode(entry.value),
      };
    }
    if (value is YamlList) {
      return value.map(_convertYamlNode).toList();
    }
    return value;
  }
}
