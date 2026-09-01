import 'package:test/test.dart';
import 'package:rekeens_flutter_cli/utils/dependency_resolver.dart';

void main() {
  test('resolves dependencies as bare package names based on options', () {
    expect(
      DependencyResolver.resolve({
        'state_management': 'riverpod',
        'router': 'go_router',
        'networking': 'dio',
        'storage': 'shared_preferences',
        'localization': true,
      }),
      ['flutter_riverpod', 'go_router', 'dio', 'shared_preferences', 'intl'],
    );

    expect(
      DependencyResolver.resolve({
        'state_management': 'none',
        'router': 'none',
        'networking': 'none',
        'storage': 'none',
        'localization': false,
      }),
      isEmpty,
    );
  });

  test('resolves bloc and http variants', () {
    expect(
      DependencyResolver.resolve({
        'state_management': 'bloc',
        'router': 'none',
        'networking': 'http',
        'storage': 'none',
        'localization': false,
      }),
      ['flutter_bloc', 'http'],
    );
  });

  test('resolves secure_storage dependency', () {
    expect(
      DependencyResolver.resolve({
        'state_management': 'none',
        'router': 'none',
        'networking': 'none',
        'storage': 'secure_storage',
        'localization': false,
      }),
      ['flutter_secure_storage'],
    );
  });

  test('resolveDevDependencies returns empty when codegen disabled', () {
    expect(
      DependencyResolver.resolveDevDependencies(includeCodegen: false),
      isEmpty,
    );
    expect(DependencyResolver.resolveDevDependencies(), isEmpty);
  });

  test('resolveDevDependencies returns codegen tools as bare names', () {
    expect(DependencyResolver.resolveDevDependencies(includeCodegen: true), [
      'build_runner',
      'freezed',
      'json_serializable',
    ]);
  });
}
