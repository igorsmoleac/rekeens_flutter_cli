import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/base_generator.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';
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
      await copyTemplate(
        templateSubPath: 'model_with_fields',
        targetDir: modelsDir,
        variables: {'model_name': modelName, 'class_name': className},
        lists: {'fields': _buildFieldVariables(parsedFields)},
      );
    }

    logger.success('Model "$modelName" created in feature "$featureName".');
  }

  List<Map<String, String>> _buildFieldVariables(List<ModelField> fields) {
    return fields.map((f) {
      return <String, String>{
        'dart_type': f.dartType,
        'name': f.name,
        'required_prefix': f.isNullable ? '' : 'required ',
        'from_json_expr': _fromJsonExpr(f),
        'json_key': "'${f.name}'",
        'to_json_expr': _toJsonExpr(f),
      };
    }).toList();
  }

  String _fromJsonExpr(ModelField f) {
    final key = "'${f.name}'";
    switch (f.baseType) {
      case 'String':
      case 'bool':
      case 'int':
        return 'json[$key] as ${f.dartType}';
      case 'double':
        return f.isNullable
            ? '(json[$key] as num?)?.toDouble()'
            : '(json[$key] as num).toDouble()';
      case 'DateTime':
        return f.isNullable
            ? 'json[$key] == null ? null : DateTime.parse(json[$key] as String)'
            : 'DateTime.parse(json[$key] as String)';
      case 'List<String>':
        return f.isNullable
            ? '(json[$key] as List?)?.cast<String>()'
            : '(json[$key] as List).cast<String>()';
      case 'List<int>':
        return f.isNullable
            ? '(json[$key] as List?)?.cast<int>()'
            : '(json[$key] as List).cast<int>()';
      case 'List<double>':
        return f.isNullable
            ? '(json[$key] as List?)?.map((e) => (e as num).toDouble()).toList()'
            : '(json[$key] as List).map((e) => (e as num).toDouble()).toList()';
      case 'List<bool>':
        return f.isNullable
            ? '(json[$key] as List?)?.cast<bool>()'
            : '(json[$key] as List).cast<bool>()';
      default:
        throw StateError('Unsupported type ${f.dartType}');
    }
  }

  String _toJsonExpr(ModelField f) {
    switch (f.baseType) {
      case 'DateTime':
        return f.isNullable
            ? '${f.name}?.toIso8601String()'
            : '${f.name}.toIso8601String()';
      default:
        return f.name;
    }
  }
}
