import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/features/{{feature_name}}/presentation/providers/{{provider_name}}_cubit.dart';
import 'package:{{project_name}}/features/{{feature_name}}/presentation/providers/{{provider_name}}_state.dart';

void main() {
  group('{{class_name}}Cubit', () {
    blocTest<{{class_name}}Cubit, {{class_name}}State>(
      'emits nothing on initial state',
      build: {{class_name}}Cubit.new,
      verify: (cubit) => expect(cubit.state, isA<{{class_name}}Initial>()),
    );
  });
}
