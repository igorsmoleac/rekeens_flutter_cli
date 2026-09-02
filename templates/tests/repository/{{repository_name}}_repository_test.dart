import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/repositories/{{repository_name}}_repository_impl.dart';

void main() {
  group('{{class_name}}Repository', () {
    test('getItems returns an empty list by default', () async {
      final repository = {{class_name}}RepositoryImpl();

      final items = await repository.getItems();

      expect(items, isEmpty);
    });
  });
}
