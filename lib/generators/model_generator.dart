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
    bool withTests = true,
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

    final testDir = p.join(
      projectDir,
      'test',
      'features',
      featureName,
      'data',
      'models',
    );
    final testPath = p.join(testDir, '${modelName}_model_test.dart');

    if (dryRun) {
      logDryRun('create model "$modelName"', targetPath);
      if (withTests) logDryRun('create model test "$modelName"', testPath);
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
      final imports = _collectImports(parsedFields);
      await copyTemplate(
        templateSubPath: 'model_with_fields',
        targetDir: modelsDir,
        variables: {'model_name': modelName, 'class_name': className},
        lists: {
          'fields': _buildFieldVariables(parsedFields),
          if (imports.isNotEmpty) 'imports': imports,
        },
      );
    }

    if (withTests) {
      await generateTest(
        testTemplateSubPath: 'model',
        testDir: testDir,
        variables: {
          'project_name': getProjectName(),
          'feature_name': featureName,
          'model_name': modelName,
          'class_name': className,
        },
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

  /// Collects unique relative import paths for custom/enum/list-custom fields.
  List<Map<String, String>> _collectImports(List<ModelField> fields) {
    final seen = <String>{};
    final imports = <Map<String, String>>[];
    for (final f in fields) {
      final path = f.importPath;
      if (path == null || seen.contains(path)) continue;
      seen.add(path);
      imports.add(<String, String>{'path': path});
    }
    return imports;
  }

  String _fromJsonExpr(ModelField f) {
    final key = "'${f.name}'";
    final nullableAccess = f.isNullable ? '?' : '';
    switch (f.category) {
      case FieldCategory.primitive:
        switch (f.baseType) {
          case 'String':
          case 'bool':
          case 'int':
            return 'json[$key] as ${f.dartType}';
          case 'double':
            return f.isNullable
                ? '(json[$key] as num?)?.toDouble()'
                : '(json[$key] as num).toDouble()';
        }
        throw StateError('Unhandled primitive ${f.dartType}');
      case FieldCategory.dateTime:
        return f.isNullable
            ? 'json[$key] == null ? null : DateTime.parse(json[$key] as String)'
            : 'DateTime.parse(json[$key] as String)';
      case FieldCategory.listPrimitive:
        switch (f.baseType) {
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
        }
        throw StateError('Unhandled list primitive ${f.dartType}');
      case FieldCategory.listCustom:
        final inner = f.innerType!;
        if (f.isNullable) {
          return '(json[$key] as List?)'
              '?.map((e) => $inner.fromJson(e as Map<String, dynamic>))'
              '.toList()';
        }
        return '(json[$key] as List)'
            '.map((e) => $inner.fromJson(e as Map<String, dynamic>))'
            '.toList()';
      case FieldCategory.custom:
        final inner = f.baseType;
        if (f.isNullable) {
          return 'json[$key] == null ? null : '
              '$inner.fromJson(json[$key] as Map<String, dynamic>)';
        }
        return '$inner.fromJson(json[$key] as Map<String, dynamic>)';
      case FieldCategory.enumType:
        final inner = f.baseType;
        if (f.isNullable) {
          return 'json[$key] == null ? null : '
              '$inner.values.byName(json[$key] as String)';
        }
        return '$inner.values.byName(json[$key] as String)';
      case FieldCategory.map:
        return 'Map<String, dynamic>.from(json[$key] as Map$nullableAccess)';
    }
  }

  String _toJsonExpr(ModelField f) {
    switch (f.category) {
      case FieldCategory.dateTime:
        return f.isNullable
            ? '${f.name}?.toIso8601String()'
            : '${f.name}.toIso8601String()';
      case FieldCategory.listCustom:
        if (f.isNullable) {
          return '${f.name}?.map((e) => e.toJson()).toList()';
        }
        return '${f.name}.map((e) => e.toJson()).toList()';
      case FieldCategory.custom:
        return f.isNullable ? '${f.name}?.toJson()' : '${f.name}.toJson()';
      case FieldCategory.enumType:
        return f.isNullable ? '${f.name}?.name' : '${f.name}.name';
      case FieldCategory.primitive:
      case FieldCategory.listPrimitive:
      case FieldCategory.map:
        return f.name;
    }
  }
}
