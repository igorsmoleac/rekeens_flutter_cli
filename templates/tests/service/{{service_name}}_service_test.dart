import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/services/{{service_name}}_service.dart';

void main() {
  group('{{class_name}}Service', () {
    test('performAction completes without throwing', () async {
      final service = {{class_name}}Service();

      await expectLater(service.performAction(), completes);
    });
  });
}
