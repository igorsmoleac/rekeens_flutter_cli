import 'package:rekeens_flutter_cli/services/prompter_service.dart';
import 'package:test/test.dart';

void main() {
  late StringBuffer output;
  late List<String> inputs;
  late int inputIndex;
  late PrompterService prompter;

  PrompterService makePrompter() {
    return PrompterService(
      output: output,
      readLine: () {
        if (inputIndex < inputs.length) {
          return inputs[inputIndex++];
        }
        return null;
      },
    );
  }

  setUp(() {
    output = StringBuffer();
    inputs = [];
    inputIndex = 0;
    prompter = makePrompter();
  });

  group('askString', () {
    test('returns user input', () {
      inputs = ['hello'];
      expect(prompter.askString('Name'), 'hello');
      expect(output.toString(), contains('Name: '));
    });

    test('returns default when input is empty', () {
      inputs = [''];
      expect(prompter.askString('Name', defaultValue: 'default_val'),
          'default_val');
      expect(output.toString(), contains('[default_val]'));
    });

    test('returns empty string when no default and input is empty', () {
      inputs = [''];
      expect(prompter.askString('Name'), '');
    });

    test('returns default when input is whitespace only', () {
      inputs = ['   '];
      expect(
        prompter.askString('Name', defaultValue: 'def'),
        'def',
      );
    });

    test('trims user input', () {
      inputs = ['  hello  '];
      expect(prompter.askString('Name'), 'hello');
    });

    test('returns empty string when stdin returns null', () {
      inputs = [];
      expect(prompter.askString('Name'), '');
    });
  });

  group('askYesNo', () {
    test('returns true for "y"', () {
      inputs = ['y'];
      expect(prompter.askYesNo('Confirm'), isTrue);
    });

    test('returns true for "yes"', () {
      inputs = ['yes'];
      expect(prompter.askYesNo('Confirm'), isTrue);
    });

    test('returns true for "Y" (case insensitive)', () {
      inputs = ['Y'];
      expect(prompter.askYesNo('Confirm'), isTrue);
    });

    test('returns false for "n"', () {
      inputs = ['n'];
      expect(prompter.askYesNo('Confirm'), isFalse);
    });

    test('returns false for "no"', () {
      inputs = ['no'];
      expect(prompter.askYesNo('Confirm'), isFalse);
    });

    test('returns default true for empty input when defaultValue=true', () {
      inputs = [''];
      expect(prompter.askYesNo('Confirm', defaultValue: true), isTrue);
    });

    test('returns default false for empty input when defaultValue=false', () {
      inputs = [''];
      expect(prompter.askYesNo('Confirm', defaultValue: false), isFalse);
    });

    test('retries on invalid input then accepts valid', () {
      inputs = ['maybe', 'y'];
      expect(prompter.askYesNo('Confirm'), isTrue);
      expect(output.toString(), contains('Please answer y or n.'));
    });

    test('shows correct hint for defaultValue=true', () {
      inputs = [''];
      prompter.askYesNo('Confirm', defaultValue: true);
      expect(output.toString(), contains('[Y/n]'));
    });

    test('shows correct hint for defaultValue=false', () {
      inputs = [''];
      prompter.askYesNo('Confirm', defaultValue: false);
      expect(output.toString(), contains('[y/N]'));
    });
  });

  group('askChoice', () {
    test('returns selected option by number', () {
      inputs = ['2'];
      expect(
        prompter.askChoice('Pick', ['a', 'b', 'c']),
        'b',
      );
    });

    test('returns default for empty input', () {
      inputs = [''];
      expect(
        prompter.askChoice('Pick', ['a', 'b', 'c'], defaultValue: 'b'),
        'b',
      );
    });

    test('retries on invalid input then accepts valid', () {
      inputs = ['xyz', '0', '1'];
      expect(
        prompter.askChoice('Pick', ['a', 'b']),
        'a',
      );
      expect(output.toString(), contains('Invalid choice. Try again.'));
    });

    test('returns empty string for empty options', () {
      expect(prompter.askChoice('Pick', []), '');
    });

    test('shows hint with default option number', () {
      inputs = [''];
      prompter.askChoice('Pick', ['a', 'b', 'c'], defaultValue: 'b');
      expect(output.toString(), contains('[2]'));
    });

    test('marks default option with asterisk', () {
      inputs = [''];
      prompter.askChoice('Pick', ['a', 'b', 'c'], defaultValue: 'b');
      expect(output.toString(), contains('* 2. b'));
    });
  });

  group('askMultipleChoice', () {
    test('returns defaults for empty input', () {
      inputs = [''];
      expect(
        prompter.askMultipleChoice(
          'Select',
          ['a', 'b', 'c'],
          defaults: ['a', 'b'],
        ),
        ['a', 'b'],
      );
    });

    test('parses comma-separated numbers', () {
      inputs = ['1,3'];
      expect(
        prompter.askMultipleChoice('Select', ['a', 'b', 'c']),
        ['a', 'c'],
      );
    });

    test('parses space-separated numbers', () {
      inputs = ['1 3'];
      expect(
        prompter.askMultipleChoice('Select', ['a', 'b', 'c']),
        ['a', 'c'],
      );
    });

    test('deduplicates selected options', () {
      inputs = ['1,1,2'];
      expect(
        prompter.askMultipleChoice('Select', ['a', 'b', 'c']),
        ['a', 'b'],
      );
    });

    test('ignores out-of-range numbers', () {
      inputs = ['1,5,2'];
      expect(
        prompter.askMultipleChoice('Select', ['a', 'b', 'c']),
        ['a', 'b'],
      );
    });

    test('ignores non-numeric input', () {
      inputs = ['abc,1,xyz'];
      expect(
        prompter.askMultipleChoice('Select', ['a', 'b', 'c']),
        ['a'],
      );
    });

    test('returns defaults when all parsed selections are invalid', () {
      inputs = ['xyz'];
      expect(
        prompter.askMultipleChoice(
          'Select',
          ['a', 'b'],
          defaults: ['a'],
        ),
        ['a'],
      );
    });

    test('returns empty list for empty options', () {
      expect(prompter.askMultipleChoice('Select', []), []);
    });

    test('marks default options with x in display', () {
      inputs = [''];
      prompter.askMultipleChoice(
        'Select',
        ['a', 'b', 'c'],
        defaults: ['b'],
      );
      expect(output.toString(), contains('[x] 2. b'));
      expect(output.toString(), contains('[ ] 1. a'));
    });

    test('returns empty defaults when no defaults and empty input', () {
      inputs = [''];
      expect(
        prompter.askMultipleChoice('Select', ['a', 'b']),
        [],
      );
    });
  });
}
