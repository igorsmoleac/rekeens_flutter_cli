import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/features/{{feature_name}}/presentation/providers/{{provider_name}}_provider.dart';
import 'package:{{project_name}}/features/{{feature_name}}/presentation/providers/{{provider_name}}_state.dart';

void main() {
  group('{{provider_name}}Provider', () {
    test('initial state has count=0 and isLoading=false', () {
      final container = ProviderContainer();

      final state = container.read({{provider_name}}Provider);

      expect(state.count, 0);
      expect(state.isLoading, isFalse);

      container.dispose();
    });

    test('doSomething increments count', () async {
      final container = ProviderContainer();

      final notifier = container.read({{provider_name}}Provider.notifier);
      await notifier.doSomething();

      expect(container.read({{provider_name}}Provider).count, 1);

      container.dispose();
    });
  });
}
