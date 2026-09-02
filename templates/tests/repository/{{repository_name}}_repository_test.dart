import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/repositories/{{repository_name}}_repository.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/repositories/{{repository_name}}_repository_impl.dart';

class _Fake{{class_name}}Repository implements {{class_name}}Repository {
  _Fake{{class_name}}Repository(this._items);

  final List<String> _items;

  @override
  Future<List<String>> getItems() async => _items;
}

void main() {
  group('{{class_name}}Repository', () {
    test('impl returns an empty list by default', () async {
      final {{class_name}}Repository repository = {{class_name}}RepositoryImpl();

      final items = await repository.getItems();

      expect(items, isEmpty);
    });

    test('fake returns the injected items through the interface', () async {
      final {{class_name}}Repository repository = _Fake{{class_name}}Repository(
        const ['alpha', 'beta'],
      );

      final items = await repository.getItems();

      expect(items, ['alpha', 'beta']);
    });
  });
}
