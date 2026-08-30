import 'package:args/command_runner.dart';
import 'package:rekeens_flutter_cli/commands/generate_command.dart';
import 'package:test/test.dart';

void main() {
  late CommandRunner<void> runner;

  setUp(() {
    runner = CommandRunner<void>('rekeens', 'Rekeens CLI test runner');
    runner.addCommand(GenerateCommand());
  });

  group('argument validation', () {
    test('throws UsageException when no type and name are provided', () {
      expect(() => runner.run(['generate']), throwsA(isA<UsageException>()));
    });

    test('throws UsageException when only type is provided', () {
      expect(
        () => runner.run(['generate', 'feature']),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws UsageException for unknown generator type', () {
      expect(
        () => runner.run(['generate', 'unknown', 'thing']),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws UsageException when screen name is missing', () {
      expect(
        () => runner.run(['generate', 'screen', 'auth']),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws UsageException when model name is missing', () {
      expect(
        () => runner.run(['generate', 'model', 'auth']),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws UsageException when repository name is missing', () {
      expect(
        () => runner.run(['generate', 'repository', 'auth']),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws UsageException when service name is missing', () {
      expect(
        () => runner.run(['generate', 'service', 'auth']),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws UsageException when provider name is missing', () {
      expect(
        () => runner.run(['generate', 'provider', 'auth']),
        throwsA(isA<UsageException>()),
      );
    });
  });

  group('flag parsing', () {
    test('accepts --force flag without error', () {
      expect(
        () => runner.run(['generate', 'feature', 'auth', '--force']),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'accepts --dry-run flag for feature and skips file creation',
      () async {
        await runner.run(['generate', 'feature', 'auth', '--dry-run']);
      },
    );

    test('accepts -f abbreviation for force', () {
      expect(
        () => runner.run(['generate', 'feature', 'auth', '-f']),
        throwsA(isA<StateError>()),
      );
    });

    test('accepts -n abbreviation for dry-run', () async {
      await runner.run(['generate', 'feature', 'auth', '-n']);
    });
  });
}
