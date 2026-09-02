import 'package:rekeens_flutter_cli/utils/arg_preprocessor.dart';
import 'package:test/test.dart';

void main() {
  group('handleVersionFlag', () {
    test('returns false when --version is absent', () async {
      expect(await handleVersionFlag(['create', 'my_app']), isFalse);
    });

    test('returns true when --version is present', () async {
      expect(await handleVersionFlag(['--version']), isTrue);
    });

    test('returns true when -v is present', () async {
      expect(await handleVersionFlag(['-v']), isTrue);
    });

    test('returns true when --version is among other args', () async {
      expect(await handleVersionFlag(['create', '--version']), isTrue);
    });
  });

  group('expandAliases', () {
    test('rewrites leading g to generate', () {
      expect(expandAliases(['g', 'auth', 'login']), ['generate', 'auth', 'login']);
    });

    test('leaves generate unchanged', () {
      expect(expandAliases(['generate', 'auth', 'login']), [
        'generate',
        'auth',
        'login',
      ]);
    });

    test('leaves non-g commands unchanged', () {
      expect(expandAliases(['create', 'my_app']), ['create', 'my_app']);
    });

    test('leaves empty args unchanged', () {
      expect(expandAliases([]), []);
    });

    test('only rewrites the first positional argument', () {
      expect(expandAliases(['g', 'g']), ['generate', 'g']);
    });

    test('does not rewrite g when it is not the first arg', () {
      expect(expandAliases(['create', 'g']), ['create', 'g']);
    });
  });
}
