import 'package:args/command_runner.dart';
import 'package:rekeens_flutter_cli/commands/generate_command.dart';
import 'package:rekeens_flutter_cli/config/hooks.dart';
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

    test('throws UsageException when entity name is missing', () {
      expect(
        () => runner.run(['generate', 'entity', 'auth']),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws UsageException when usecase name is missing', () {
      expect(
        () => runner.run(['generate', 'usecase', 'auth']),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws UsageException when datasource name is missing', () {
      expect(
        () => runner.run(['generate', 'datasource', 'auth']),
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

  group('model field update flags', () {
    test('rejects --add-field for non-model generator types', () {
      expect(
        () => runner.run([
          'generate',
          'feature',
          'auth',
          '--add-field',
          'email:string',
        ]),
        throwsA(
          isA<UsageException>().having(
            (e) => e.message,
            'message',
            contains('only supported for models'),
          ),
        ),
      );
    });

    test('throws UsageException when model name is missing in update mode', () {
      expect(
        () => runner.run([
          'generate',
          'model',
          'auth',
          '--add-field',
          'email:string',
        ]),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws UsageException when positional fields are combined with '
        '--add-field', () {
      expect(
        () => runner.run([
          'generate',
          'model',
          'auth',
          'user',
          'name:string',
          '--add-field',
          'email:string',
        ]),
        throwsA(
          isA<UsageException>().having(
            (e) => e.message,
            'message',
            contains('cannot be combined'),
          ),
        ),
      );
    });

    test('accepts repeated --add-field and --remove-field options', () async {
      await expectLater(
        runner.run([
          'generate',
          'model',
          'auth',
          'user',
          '--add-field',
          'email:string',
          '--add-field',
          'age:int?',
          '--remove-field',
          'name',
          '--dry-run',
        ]),
        throwsA(isNot(isA<UsageException>())),
      );
    });
  });

  group('hooks flag', () {
    test('accepts --no-hooks flag without error', () async {
      final fakeRunner = _FakeHookRunner();
      final r = CommandRunner<void>('rekeens', 'test');
      r.addCommand(GenerateCommand(hookRunner: fakeRunner));
      await r.run(['generate', 'feature', 'auth', '--no-hooks', '--dry-run']);
      expect(fakeRunner.runCalls, 0);
    });

    test('does not call hooks when --hooks is disabled', () async {
      final fakeRunner = _FakeHookRunner();
      final r = CommandRunner<void>('rekeens', 'test');
      r.addCommand(GenerateCommand(hookRunner: fakeRunner));
      await r.run(['generate', 'feature', 'auth', '--no-hooks', '--dry-run']);
      expect(fakeRunner.runCalls, 0);
    });
  });
}

class _FakeHookRunner extends HookRunner {
  _FakeHookRunner() : super();

  int runCalls = 0;
  List<String> generatorTypes = [];

  @override
  Future<void> runHooks(List<HookConfig> hooks, HookContext context) async {
    runCalls++;
    generatorTypes.add(context.generatorType);
  }
}
