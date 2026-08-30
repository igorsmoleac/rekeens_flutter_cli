import 'package:rekeens_flutter_cli/utils/model_fields.dart';
import 'package:test/test.dart';

void main() {
  group('parseModelField', () {
    test('parses name:type', () {
      final f = parseModelField('name:string');
      expect(f.name, 'name');
      expect(f.dartType, 'String');
      expect(f.isNullable, isFalse);
      expect(f.baseType, 'String');
    });

    test('normalizes lowercase type aliases', () {
      expect(parseModelField('age:int').dartType, 'int');
      expect(parseModelField('price:double').dartType, 'double');
      expect(parseModelField('active:bool').dartType, 'bool');
      expect(parseModelField('createdAt:datetime').dartType, 'DateTime');
      expect(parseModelField('createdAt:date').dartType, 'DateTime');
      expect(parseModelField('tags:list<string>').dartType, 'List<String>');
    });

    test('supports [] array syntax', () {
      expect(parseModelField('tags:string[]').dartType, 'List<String>');
      expect(parseModelField('ids:int[]').dartType, 'List<int>');
      expect(parseModelField('prices:double[]').dartType, 'List<double>');
      expect(parseModelField('flags:bool[]').dartType, 'List<bool>');
    });

    test('supports nullable [] array syntax', () {
      expect(parseModelField('tags:string[]?').dartType, 'List<String>?');
    });

    test('parses nullable type', () {
      final f = parseModelField('age:int?');
      expect(f.name, 'age');
      expect(f.dartType, 'int?');
      expect(f.isNullable, isTrue);
      expect(f.baseType, 'int');
    });

    test('parses List<String>', () {
      final f = parseModelField('tags:List<String>');
      expect(f.name, 'tags');
      expect(f.dartType, 'List<String>');
    });

    test('parses DateTime', () {
      final f = parseModelField('createdAt:DateTime');
      expect(f.dartType, 'DateTime');
    });

    test('parses double', () {
      final f = parseModelField('price:double');
      expect(f.dartType, 'double');
    });

    test('trims whitespace', () {
      final f = parseModelField('  name : string  ');
      expect(f.name, 'name');
      expect(f.dartType, 'String');
    });

    test('rejects empty input', () {
      expect(() => parseModelField(''), throwsA(isA<FormatException>()));
      expect(() => parseModelField('   '), throwsA(isA<FormatException>()));
    });

    test('rejects missing colon', () {
      expect(
        () => parseModelField('namestring'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects missing name', () {
      expect(() => parseModelField(':string'), throwsA(isA<FormatException>()));
    });

    test('rejects missing type', () {
      expect(() => parseModelField('name:'), throwsA(isA<FormatException>()));
    });

    test('rejects invalid field name (PascalCase)', () {
      expect(
        () => parseModelField('Name:string'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid field name (starts with digit)', () {
      expect(
        () => parseModelField('1name:string'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unsupported type', () {
      expect(
        () => parseModelField('data:Map<String,int>'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('parseModelFields', () {
    test('parses multiple fields', () {
      final fields = parseModelFields(['name:string', 'age:int']);
      expect(fields.length, 2);
      expect(fields[0].name, 'name');
      expect(fields[1].name, 'age');
    });

    test('returns empty list for empty input', () {
      expect(parseModelFields([]), isEmpty);
    });

    test('rejects duplicate field names', () {
      expect(
        () => parseModelFields(['name:string', 'name:int']),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
