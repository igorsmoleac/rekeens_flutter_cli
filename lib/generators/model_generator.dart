import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';
import 'package:rekeens_flutter_cli/utils/model_fields.dart';

class ModelGenerator extends BaseGenerator {
  ModelGenerator({
    super.templateService,
    super.templatesRootOverride,
    super.workingDirectory,
  });

  Future<void> generate(
    String featureName,
    String modelName, {
    List<String>? fields,
    bool force = false,
    bool dryRun = false,
  }) async {
    if (featureName.isEmpty || modelName.isEmpty) {
      throw Exception('Feature name and model name are required.');
    }
    if (!isSnakeCase(featureName) || !isSnakeCase(modelName)) {
      throw Exception('Names must be in snake_case.');
    }

    final parsedFields = fields == null ? null : parseModelFields(fields);

    final featureDir = getFeatureDir(featureName);
    final modelsDir = p.join(featureDir, 'data', 'models');
    final targetPath = p.join(modelsDir, '${modelName}_model.dart');
    checkFileExists(targetPath, 'Model "$modelName"', force: force);

    if (dryRun) {
      logDryRun('create model "$modelName"', targetPath);
      return;
    }

    ensureDirectory(modelsDir);

    final className = toPascalCase(modelName);

    if (parsedFields == null || parsedFields.isEmpty) {
      await copyTemplate(
        templateSubPath: 'model',
        targetDir: modelsDir,
        variables: {'model_name': modelName, 'class_name': className},
      );
    } else {
      final content = _generateModelSource('${className}Model', parsedFields);
      File(p.join(modelsDir, '${modelName}_model.dart'))
          .writeAsStringSync(content);
    }

    print('Model "$modelName" created in feature "$featureName".');
  }

  String generateSourceForTest(String className, List<ModelField> fields) =>
      _generateModelSource(className, fields);

  String _generateModelSource(String className, List<ModelField> fields) {
    final buf = StringBuffer();

    buf.writeln('class $className {');
    for (final f in fields) {
      buf.writeln('  final ${f.dartType} ${f.name};');
    }
    buf.writeln();

    buf.writeln('  const $className({');
    for (final f in fields) {
      buf.writeln('    ${f.isNullable ? '' : 'required '}this.${f.name},');
    }
    buf.writeln('  });');
    buf.writeln();

    buf.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');
    buf.writeln('    return $className(');
    for (final f in fields) {
      buf.writeln('      ${f.name}: ${_fromJsonExpr(f)},');
    }
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();

    buf.writeln('  Map<String, dynamic> toJson() {');
    buf.writeln('    return {');
    for (final f in fields) {
      buf.writeln('      ${_jsonKey(f.name)}: ${_toJsonExpr(f)},');
    }
    buf.writeln('    };');
    buf.writeln('  }');

    buf.writeln('}');

    return buf.toString();
  }

  String _jsonKey(String name) => "'$name'";

  String _fromJsonExpr(ModelField f) {
    final key = _jsonKey(f.name);
    switch (f.baseType) {
      case 'String':
      case 'bool':
      case 'int':
        return "json[$key] as ${f.dartType}";
      case 'double':
        return f.isNullable
            ? "(json[$key] as num?)?.toDouble()"
            : "(json[$key] as num).toDouble()";
      case 'DateTime':
        return f.isNullable
            ? "json[$key] == null ? null : DateTime.parse(json[$key] as String)"
            : "DateTime.parse(json[$key] as String)";
      case 'List<String>':
        return f.isNullable
            ? "(json[$key] as List?)?.cast<String>()"
            : "(json[$key] as List).cast<String>()";
      case 'List<int>':
        return f.isNullable
            ? "(json[$key] as List?)?.cast<int>()"
            : "(json[$key] as List).cast<int>()";
      case 'List<double>':
        return f.isNullable
            ? "(json[$key] as List?)?.map((e) => (e as num).toDouble()).toList()"
            : "(json[$key] as List).map((e) => (e as num).toDouble()).toList()";
      case 'List<bool>':
        return f.isNullable
            ? "(json[$key] as List?)?.cast<bool>()"
            : "(json[$key] as List).cast<bool>()";
      default:
        throw StateError('Unsupported type ${f.dartType}');
    }
  }

  String _toJsonExpr(ModelField f) {
    switch (f.baseType) {
      case 'DateTime':
        return f.isNullable
            ? "${f.name}?.toIso8601String()"
            : "${f.name}.toIso8601String()";
      default:
        return f.name;
    }
  }
}
