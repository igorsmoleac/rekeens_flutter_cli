/// Categories of field types recognized by the model generator.
enum FieldCategory {
  /// String, int, double, bool.
  primitive,

  /// DateTime.
  dateTime,

  /// List of primitives (`List<String>`, `List<int>`, etc.).
  listPrimitive,

  /// List of custom models (`List<UserModel>`).
  listCustom,

  /// Custom model class (`UserModel`).
  custom,

  /// Enum (`Role`).
  enumType,

  /// `Map<String, dynamic>`.
  map,
}

class ModelField {
  const ModelField({
    required this.name,
    required this.dartType,
    required this.category,
    this.importPath,
    this.innerType,
  });

  final String name;
  final String dartType;
  final FieldCategory category;

  /// Relative import path for custom/enum types (e.g. 'user_model.dart'),
  /// or `null` for primitives, DateTime, List of primitives, and Map.
  final String? importPath;

  /// For [listCustom] and [listPrimitive]: the element type without the
  /// `List<>` wrapper (e.g. `UserModel`, `String`).
  /// For other categories: `null`.
  final String? innerType;

  bool get isNullable => dartType.endsWith('?');
  String get baseType =>
      isNullable ? dartType.substring(0, dartType.length - 1) : dartType;
}

const _primitiveTypes = <String>{'String', 'int', 'double', 'bool'};

const _listPrimitiveTypes = <String>{
  'List<String>',
  'List<int>',
  'List<double>',
  'List<bool>',
};

final _typeAliases = <String, String>{
  for (final t in {..._primitiveTypes, ..._listPrimitiveTypes})
    t.toLowerCase(): t,
  'datetime': 'DateTime',
  'date': 'DateTime',
  'string[]': 'List<String>',
  'int[]': 'List<int>',
  'double[]': 'List<double>',
  'bool[]': 'List<bool>',
};

/// Regex for a PascalCase identifier (custom model or enum name).
final _pascalCaseRegex = RegExp(r'^[A-Z][a-zA-Z0-9]*$');

/// Regex for `List<PascalCase>` (custom model list).
final _listCustomRegex = RegExp(r'^List<([A-Z][a-zA-Z0-9]*)>$');

/// Regex for `list<pascalcase>` (case-insensitive alias for `List<Custom>`).
final _listCustomAliasRegex = RegExp(r'^list<([A-Z][a-zA-Z0-9]*)>$');

ModelField parseModelField(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    throw FormatException('Field definition cannot be empty.');
  }

  final colonIndex = trimmed.indexOf(':');
  if (colonIndex <= 0 || colonIndex == trimmed.length - 1) {
    throw FormatException(
      'Invalid field format "$input". Expected "name:type".',
    );
  }

  final name = trimmed.substring(0, colonIndex).trim();
  final type = trimmed.substring(colonIndex + 1).trim();

  if (name.isEmpty || !RegExp(r'^[a-z][a-zA-Z0-9_]*$').hasMatch(name)) {
    throw FormatException(
      'Invalid field name "$name". Use lowerCamelCase starting with a letter.',
    );
  }

  final isNullable = type.endsWith('?');
  final rawType = isNullable ? type.substring(0, type.length - 1) : type;

  final parsed = _parseType(rawType);
  final dartType = isNullable ? '${parsed.dartType}?' : parsed.dartType;

  return ModelField(
    name: name,
    dartType: dartType,
    category: parsed.category,
    importPath: parsed.importPath,
    innerType: parsed.innerType,
  );
}

/// Result of parsing a (non-nullable) type string.
class _ParsedType {
  const _ParsedType({
    required this.dartType,
    required this.category,
    this.importPath,
    this.innerType,
  });

  final String dartType;
  final FieldCategory category;
  final String? importPath;
  final String? innerType;
}

_ParsedType _parseType(String rawType) {
  // 1. Primitives and aliased list-of-primitives.
  final canonical = _typeAliases[rawType.toLowerCase()];
  if (canonical != null) {
    if (_primitiveTypes.contains(canonical)) {
      return _ParsedType(
        dartType: canonical,
        category: FieldCategory.primitive,
      );
    }
    if (canonical == 'DateTime') {
      return _ParsedType(dartType: canonical, category: FieldCategory.dateTime);
    }
    // List of primitives.
    final inner = canonical.substring(5, canonical.length - 1);
    return _ParsedType(
      dartType: canonical,
      category: FieldCategory.listPrimitive,
      innerType: inner,
    );
  }

  // 2. Map<String, dynamic> (case-insensitive).
  if (rawType.toLowerCase() == 'map<string, dynamic>' ||
      rawType.toLowerCase() == 'map<string,dynamic>') {
    return const _ParsedType(
      dartType: 'Map<String, dynamic>',
      category: FieldCategory.map,
    );
  }

  // 3. List<CustomModel> — PascalCase inside List<>.
  final listCustomMatch =
      _listCustomRegex.firstMatch(rawType) ??
      _listCustomAliasRegex.firstMatch(rawType);
  if (listCustomMatch != null) {
    final inner = listCustomMatch.group(1)!;
    final dartType = 'List<$inner>';
    return _ParsedType(
      dartType: dartType,
      category: FieldCategory.listCustom,
      importPath: '${_toSnakeCase(inner)}.dart',
      innerType: inner,
    );
  }

  // 4. enum Name — explicit enum keyword.
  if (rawType.startsWith('enum ')) {
    final enumName = rawType.substring(5).trim();
    if (!_pascalCaseRegex.hasMatch(enumName)) {
      throw FormatException(
        'Invalid enum name "$enumName" in "$rawType". Use PascalCase.',
      );
    }
    return _ParsedType(
      dartType: enumName,
      category: FieldCategory.enumType,
      importPath: '${_toSnakeCase(enumName)}.dart',
    );
  }

  // 5. Custom model class — bare PascalCase identifier.
  if (_pascalCaseRegex.hasMatch(rawType)) {
    return _ParsedType(
      dartType: rawType,
      category: FieldCategory.custom,
      importPath: '${_toSnakeCase(rawType)}.dart',
    );
  }

  throw FormatException(
    'Unsupported type "$rawType". '
    'Supported: primitives, DateTime, List<primitive>, List<CustomModel>, '
    'CustomModel, enum Name, Map<String, dynamic> (and nullable variants).',
  );
}

/// Converts a PascalCase name to snake_case (e.g. `UserModel` → `user_model`).
String _toSnakeCase(String pascal) {
  return pascal
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (m) => m.start == 0 ? m[0]!.toLowerCase() : '_${m[0]!.toLowerCase()}',
      )
      .toLowerCase();
}

List<ModelField> parseModelFields(List<String> inputs) {
  if (inputs.isEmpty) return [];
  final fields = <ModelField>[];
  final seen = <String>{};
  for (final input in inputs) {
    final field = parseModelField(input);
    if (seen.contains(field.name)) {
      throw FormatException('Duplicate field name "${field.name}".');
    }
    seen.add(field.name);
    fields.add(field);
  }
  return fields;
}
