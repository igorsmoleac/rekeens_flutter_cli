import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/entities/{{entity_name}}_entity.dart';

void main() {
  group('{{class_name}}Entity', () {
    test('two entities with the same id are equal', () {
      const a = {{class_name}}Entity(id: '1');
      const b = {{class_name}}Entity(id: '1');

      expect(a, equals(b));
    });

    test('entities with different ids are not equal', () {
      const a = {{class_name}}Entity(id: '1');
      const b = {{class_name}}Entity(id: '2');

      expect(a, isNot(equals(b)));
    });
  });
}
