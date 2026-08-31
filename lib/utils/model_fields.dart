class ModelField {
  const ModelField({required this.name, required this.dartType});
  final String name;
  final String dartType;

  bool get isNullable => dartType.endsWith('?');
  String get baseType =>
      isNullable ? dartType.substring(0, dartType.length - 1) : dartType;
}

const _supportedTypes = <String>{
  'String',
  'int',
  'double',
  'bool',
  'DateTime',
  'List<String>',
  'List<int>',
  'List<double>',
  'List<bool>',
};

final _typeAliases = <String, String>{
  for (final t in _supportedTypes) t.toLowerCase(): t,
  'datetime': 'DateTime',
  'date': 'DateTime',
  'string[]': 'List<String>',
  'int[]': 'List<int>',
  'double[]': 'List<double>',
  'bool[]': 'List<bool>',
};

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
  final canonical = _typeAliases[rawType.toLowerCase()];

  if (canonical == null) {
    throw FormatException(
      'Unsupported type "$type". Supported types: ${_supportedTypes.join(', ')} (and nullable variants).',
    );
  }

  final dartType = isNullable ? '$canonical?' : canonical;

  return ModelField(name: name, dartType: dartType);
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
