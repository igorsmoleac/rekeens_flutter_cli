import 'package:test/test.dart';
import 'package:rekeens_flutter_cli/utils/dependency_resolver.dart';

void main() {
  test('resolves dependencies based on options', () {
    expect(
      DependencyResolver.resolve({
        'state_management': 'riverpod',
        'router': 'go_router',
        'networking': 'dio',
        'localization': true,
      }),
      ['flutter_riverpod', 'go_router', 'dio', 'intl'],
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
}
