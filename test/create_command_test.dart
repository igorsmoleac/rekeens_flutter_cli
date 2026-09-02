import 'package:args/command_runner.dart';
import 'package:rekeens_flutter_cli/commands/create_command.dart';
import 'package:test/test.dart';

void main() {
  group('CreateCommand', () {
    test('throws UsageException when project name is missing', () async {
      final command = CreateCommand();
      final runner = CommandRunner<void>('test', 'test runner')
        ..addCommand(command);

      expect(() => runner.run(['create']), throwsA(isA<UsageException>()));
    });

    test('throws UsageException for invalid project name', () async {
      final command = CreateCommand();
      final runner = CommandRunner<void>('test', 'test runner')
        ..addCommand(command);

      expect(
        () => runner.run(['create', 'InvalidName']),
        throwsA(
          isA<UsageException>().having(
            (e) => e.message,
            'message',
            contains('Invalid project name'),
          ),
        ),
      );
    });

    test('throws UsageException for too many arguments', () async {
      final command = CreateCommand();
      final runner = CommandRunner<void>('test', 'test runner')
        ..addCommand(command);

      expect(
        () => runner.run(['create', 'valid_name', 'extra']),
        throwsA(
          isA<UsageException>().having(
            (e) => e.message,
            'message',
            contains('Too many arguments'),
          ),
        ),
      );
    });
  });
}
