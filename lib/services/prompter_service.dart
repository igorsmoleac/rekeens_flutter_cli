import 'dart:io';

class PrompterService {
  const PrompterService();

  String askString(String question, {String? defaultValue}) {
    final hint = defaultValue != null ? ' [$defaultValue]' : '';
    stdout.write('$question$hint: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    if (input.isEmpty && defaultValue != null) {
      return defaultValue;
    }
    return input;
  }

  bool askYesNo(String question, {bool defaultValue = false}) {
    final hint = defaultValue ? '[Y/n]' : '[y/N]';
    while (true) {
      stdout.write('$question $hint: ');
      final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
      if (input.isEmpty) return defaultValue;
      if (input == 'y' || input == 'yes') return true;
      if (input == 'n' || input == 'no') return false;
      print('Please answer y or n.');
    }
  }

  List<String> askMultipleChoice(
    String question,
    List<String> options, {
    List<String>? defaults,
  }) {
    if (options.isEmpty) return [];
    if (defaults == null || defaults.isEmpty) {
      defaults = const [];
    }

    print('\n$question');
    for (var i = 0; i < options.length; i++) {
      final marker = defaults.contains(options[i]) ? 'x' : ' ';
      print('  [$marker] ${i + 1}. ${options[i]}');
    }

    stdout.write(
      'Enter numbers separated by comma (default: ${defaults.isEmpty ? "none" : defaults.join(", ")}): ',
    );
    final input = stdin.readLineSync()?.trim() ?? '';

    if (input.isEmpty) {
      return defaults;
    }

    final selected = <String>[];
    final parts = input.split(RegExp(r'[,\s]+'));
    for (final part in parts) {
      final index = int.tryParse(part);
      if (index != null && index >= 1 && index <= options.length) {
        final option = options[index - 1];
        if (!selected.contains(option)) {
          selected.add(option);
        }
      }
    }

    if (selected.isEmpty) {
      return defaults;
    }
    return selected;
  }

  String askChoice(
    String question,
    List<String> options, {
    String? defaultValue,
  }) {
    if (options.isEmpty) return '';
    print('\n$question');
    for (var i = 0; i < options.length; i++) {
      final marker = options[i] == defaultValue ? '*' : ' ';
      print('  $marker ${i + 1}. ${options[i]}');
    }

    while (true) {
      final hint = defaultValue != null
          ? ' [${options.indexOf(defaultValue) + 1}]'
          : '';
      stdout.write('Enter number$hint: ');
      final input = stdin.readLineSync()?.trim() ?? '';
      if (input.isEmpty && defaultValue != null) {
        return defaultValue;
      }
      final index = int.tryParse(input);
      if (index != null && index >= 1 && index <= options.length) {
        return options[index - 1];
      }
      print('Invalid choice. Try again.');
    }
  }
}
