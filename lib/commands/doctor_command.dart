import 'dart:io';

import 'package:args/command_runner.dart';

class DoctorCommand extends Command<void> {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Check the development environment.';

  @override
  Future<void> run() async {
    print('Rekeens CLI Doctor\n');

    var allGood = true;

    allGood = await _checkTool('Dart', ['--version']) && allGood;
    allGood = await _checkTool('Flutter', ['--version']) && allGood;
    allGood = await _checkTool('Git', ['--version']) && allGood;

    if (allGood) {
      print('\nEnvironment is ready.');
    } else {
      print('\nSome tools are missing or not in PATH.');
      exitCode = 1;
    }
  }

  Future<bool> _checkTool(String name, List<String> args) async {
    try {
      final executable = Platform.isWindows ? 'cmd' : name;
      final fullArgs = Platform.isWindows ? ['/c', name, ...args] : args;

      final result = await Process.run(executable, fullArgs);
      if (result.exitCode != 0) {
        print('✗ $name: failed to run');
        return false;
      }
      final version = _extractVersion(name, result.stdout.toString());
      print('✓ $name $version');
      return true;
    } on ProcessException {
      print('✗ $name: not found');
      return false;
    }
  }

  String _extractVersion(String tool, String output) {
    final lines = output.trim().split('\n');
    if (lines.isEmpty) return '';

    var line = lines.first.trim();

    line = line.replaceAll('•', '-');
    line = line.replaceAll(RegExp(r'[^\x00-\x7F]'), '');

    if (tool == 'Dart') {
      final match = RegExp(r'Dart SDK version: (\S+)').firstMatch(line);
      if (match != null) return 'Dart ${match.group(1)}';
    }

    if (tool == 'Flutter') {
      final match = RegExp(r'Flutter (\S+)').firstMatch(line);
      if (match != null) return 'Flutter ${match.group(1)}';
    }

    return line;
  }
}
