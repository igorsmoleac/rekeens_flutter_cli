import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/features/{{feature_name}}/domain/usecases/{{usecase_name}}_usecase.dart';

void main() {
  group('{{class_name}}UseCase', () {
    test('call returns the injected input', () async {
      final useCase = {{class_name}}UseCase();

      final result = await useCase(const {{class_name}}Params(input: 'hello'));

      expect(result, 'hello');
    });

    test('call returns empty string when input is null', () async {
      final useCase = {{class_name}}UseCase();

      final result = await useCase(const {{class_name}}Params());

      expect(result, '');
    });
  });
}
