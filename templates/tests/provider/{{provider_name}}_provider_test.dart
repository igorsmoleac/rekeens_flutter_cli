import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/features/{{feature_name}}/presentation/providers/{{provider_name}}_provider.dart';

void main() {
  group('{{provider_name}}Provider', () {
    test('provider returns a {{class_name}}Provider instance', () {
      final container = ProviderContainer();

      final provider = container.read({{provider_name}}Provider);

      expect(provider, isA<{{class_name}}Provider>());

      container.dispose();
    });
  });
}
