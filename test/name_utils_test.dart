import 'package:test/test.dart';
import 'package:rekeens_flutter_cli/generators/base_generator.dart';

class TestGenerator extends BaseGenerator {}

void main() {
  final generator = TestGenerator();

  group('isSnakeCase', () {
    test('valid snake_case', () {
      expect(generator.isSnakeCase('user_profile'), isTrue);
      expect(generator.isSnakeCase('auth2'), isTrue);
    });

    test('invalid cases', () {
      expect(generator.isSnakeCase('UserProfile'), isFalse);
      expect(generator.isSnakeCase('user-profile'), isFalse);
      expect(generator.isSnakeCase(''), isFalse);
    });
  });

  group('toPascalCase', () {
    test('converts snake_case to PascalCase', () {
      expect(generator.toPascalCase('user_profile'), 'UserProfile');
      expect(generator.toPascalCase('auth'), 'Auth');
    });

    test('handles empty parts', () {
      expect(generator.toPascalCase('_private'), 'Private');
    });
  });
}
