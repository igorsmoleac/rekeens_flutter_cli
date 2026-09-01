import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/models/{{model_name}}_model.dart';

void main() {
  group('{{class_name}}Model', () {
    test('supports value equality via constructor', () {
      final model1 = const {{class_name}}Model(id: 1, name: 'Test');
      final model2 = const {{class_name}}Model(id: 1, name: 'Test');

      expect(model1.id, model2.id);
      expect(model1.name, model2.name);
    });

    test('fromJson creates a valid model', () {
      final json = {'id': 42, 'name': 'Example'};

      final model = {{class_name}}Model.fromJson(json);

      expect(model.id, 42);
      expect(model.name, 'Example');
    });

    test('toJson produces a valid map', () {
      const model = {{class_name}}Model(id: 42, name: 'Example');

      final json = model.toJson();

      expect(json['id'], 42);
      expect(json['name'], 'Example');
    });

    test('toJson/fromJson round-trip preserves data', () {
      const original = {{class_name}}Model(id: 7, name: 'Round');
      final roundTrip = {{class_name}}Model.fromJson(original.toJson());

      expect(roundTrip.id, original.id);
      expect(roundTrip.name, original.name);
    });
  });
}
