import 'package:rekeens_flutter_cli/commands/doctor_command.dart';
import 'package:test/test.dart';

void main() {
  late DoctorCommand command;

  setUp(() {
    command = DoctorCommand();
  });

  group('extractVersion', () {
    test('parses Dart SDK version', () {
      const output =
          'Dart SDK version: 3.5.0 (stable) (Tue Aug 27 00:00:00 2024)';
      expect(command.extractVersion('Dart', output), 'Dart 3.5.0');
    });

    test('parses Flutter version', () {
      const output = 'Flutter 3.24.0 • channel stable • https://github.com';
      expect(command.extractVersion('Flutter', output), 'Flutter 3.24.0');
    });

    test('strips non-ASCII bullet characters from Flutter output', () {
      const output = 'Flutter 3.24.0 \u2022 channel stable';
      final result = command.extractVersion('Flutter', output);
      expect(result.contains('\u2022'), isFalse);
      expect(result, 'Flutter 3.24.0');
    });

    test('replaces bullet with dash before stripping non-ASCII', () {
      const output = 'git version 2.45.0 \u2022 extra';
      final result = command.extractVersion('Git', output);
      expect(result.contains('- extra'), isTrue);
      expect(result.contains('\u2022'), isFalse);
    });

    test('returns trimmed first line for Git', () {
      const output = 'git version 2.45.0\nextra line';
      expect(command.extractVersion('Git', output), 'git version 2.45.0');
    });

    test('returns empty string for empty output', () {
      expect(command.extractVersion('Dart', ''), '');
    });

    test('returns trimmed line for whitespace-only output', () {
      expect(command.extractVersion('Dart', '   \n  '), '');
    });

    test('returns raw line when no known pattern matches', () {
      const output = 'some unknown tool 1.2.3';
      expect(
        command.extractVersion('Unknown', output),
        'some unknown tool 1.2.3',
      );
    });

    test('returns raw line for Dart output without SDK marker', () {
      const output = 'Dart 3.5.0 (stable)';
      expect(command.extractVersion('Dart', output), 'Dart 3.5.0 (stable)');
    });

    test('handles multiline Dart output by using first line', () {
      const output =
          'Dart SDK version: 3.5.0 (stable)\non "windows"\nmore info';
      expect(command.extractVersion('Dart', output), 'Dart 3.5.0');
    });
  });
}
