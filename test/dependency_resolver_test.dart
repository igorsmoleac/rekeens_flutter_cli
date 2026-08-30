import 'package:test/test.dart';
import 'package:rekeens_flutter_cli/utils/dependency_resolver.dart';

void main() {
  test('resolves dependencies with versions based on options', () {
    expect(
      DependencyResolver.resolve({
        'state_management': 'riverpod',
        'router': 'go_router',
        'networking': 'dio',
        'localization': true,
      }),
      [
        'flutter_riverpod:^3.4.2',
        'go_router:^18.0.0',
        'dio:^5.11.0',
        'intl:^0.20.3',
      ],
    );

    expect(
      DependencyResolver.resolve({
        'state_management': 'none',
        'router': 'none',
        'networking': 'none',
        'localization': false,
      }),
      isEmpty,
    );
  });

  test('resolves bloc and http variants with versions', () {
    expect(
      DependencyResolver.resolve({
        'state_management': 'bloc',
        'router': 'none',
        'networking': 'http',
        'localization': false,
      }),
      ['flutter_bloc:^9.1.1', 'http:^1.6.0'],
    );
  });

  test('resolveDevDependencies returns empty when codegen disabled', () {
    expect(
      DependencyResolver.resolveDevDependencies(includeCodegen: false),
      isEmpty,
    );
    expect(DependencyResolver.resolveDevDependencies(), isEmpty);
  });

  test('resolveDevDependencies returns codegen tools with versions', () {
    expect(DependencyResolver.resolveDevDependencies(includeCodegen: true), [
      'build_runner:^2.15.1',
      'freezed:^3.2.5',
      'json_serializable:^6.14.0',
    ]);
  });
}
