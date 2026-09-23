import 'package:rekeens_flutter_cli/utils/model_fields.dart';

final _fieldDeclRegex = RegExp(
  r'^\s*final\s+(.+?)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*;$',
);

final _fromJsonEntryRegex = RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*):(.*)$');

/// The result of parsing an existing model file.
class ParsedModelFile {
  const ParsedModelFile({required this.fields});

  final List<ModelField> fields;
}

/// Parses the fields of a generated model file source.
///
/// Field declarations are matched by their `final <type> <name>;` form and
/// re-parsed through [parseModelField] so categories, import paths, and inner
/// types are reconstructed with the same rules used at generation time. The
/// `fromJson` body is inspected to tell enum fields (which use
/// `.values.byName(...)`) apart from custom model fields, since both render
/// as a bare PascalCase type in the declaration.
///
/// Throws [FormatException] when the source contains no field declarations
/// or a declaration uses an unsupported type.
ParsedModelFile parseModelFileSource(String source) {
  final fromJsonExprs = _extractFromJsonExprs(source);

  final fields = <ModelField>[];
  final seen = <String>{};
  for (final line in source.split('\n')) {
    final match = _fieldDeclRegex.firstMatch(line);
    if (match == null) continue;

    final dartType = match.group(1)!.trim();
    final name = match.group(2)!;
    if (!seen.add(name)) {
      throw FormatException('Duplicate field "$name" in model file.');
    }

    fields.add(_reconstructField(name, dartType, fromJsonExprs[name]));
  }

  if (fields.isEmpty) {
    throw const FormatException(
      'No field declarations found in model file. '
      'Expected lines like "final String name;".',
    );
  }

  return ParsedModelFile(fields: fields);
}

/// Rebuilds a [ModelField] from a `final <type> <name>;` declaration.
///
/// Enum fields cannot be recognized from the declaration alone (a bare
/// PascalCase type), so the matching `fromJson` expression is used as a hint.
ModelField _reconstructField(String name, String dartType, String? fromJsonExpr) {
  final ModelField field;
  try {
    field = parseModelField('$name:$dartType');
  } on FormatException catch (e) {
    throw FormatException(
      'Cannot parse field "$name" (type "$dartType") in model file: '
      '${e.message}',
    );
  }

  if (field.category == FieldCategory.custom &&
      fromJsonExpr != null &&
      fromJsonExpr.contains('.values.byName(')) {
    return ModelField(
      name: field.name,
      dartType: field.dartType,
      category: FieldCategory.enumType,
      importPath: field.importPath,
    );
  }
  return field;
}

/// Maps field names to their `fromJson` initializer expressions.
///
/// Entries are `name: expr,` lines inside the `fromJson` factory body;
/// expressions wrapped over multiple lines are accumulated until a line ends
/// with a comma.
Map<String, String> _extractFromJsonExprs(String source) {
  final factoryMatch = RegExp(
    r'factory\s+\w+\.fromJson\s*\([^)]*\)\s*\{',
  ).firstMatch(source);
  if (factoryMatch == null) return const {};

  final bodyStart = factoryMatch.end;
  var depth = 1;
  var i = bodyStart;
  while (i < source.length && depth > 0) {
    final ch = source[i];
    if (ch == '{') depth++;
    if (ch == '}') depth--;
    i++;
  }
  final body = source.substring(bodyStart, i - 1);

  final exprs = <String, String>{};
  String? currentName;
  final buffer = StringBuffer();

  void flush() {
    if (currentName == null) return;
    exprs[currentName!] = buffer.toString().trim();
    currentName = null;
    buffer.clear();
  }

  for (final line in body.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    final entry = _fromJsonEntryRegex.firstMatch(trimmed);
    if (entry != null && currentName == null) {
      currentName = entry.group(1)!;
      buffer.write(entry.group(2)!);
    } else if (currentName != null) {
      buffer.write(' $trimmed');
    }

    if (currentName != null && trimmed.endsWith(',')) flush();
  }
  flush();

  return exprs;
}
