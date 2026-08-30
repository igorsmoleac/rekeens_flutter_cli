import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

class DoctorCommand extends Command<void> {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Check the development environment.';

  @override
  Future<void> run() async {
    logger.info('Rekeens CLI Doctor');
    logger.info('');

    var allGood = true;

    allGood = await _checkTool('Dart', ['--version']) && allGood;
    allGood = await _checkTool('Flutter', ['--version']) && allGood;
    allGood = await _checkTool('Git', ['--version']) && allGood;

    if (allGood) {
      logger.info('');
      logger.success('Environment is ready.');
    } else {
      logger.info('');
      logger.err('Some tools are missing or not in PATH.');
      exitCode = 1;
    }
  }

  Future<bool> _checkTool(String name, List<String> args) async {
    try {
      final executable = Platform.isWindows ? 'cmd' : name;
      final fullArgs = Platform.isWindows ? ['/c', name, ...args] : args;

      final result = await Process.run(executable, fullArgs);
      if (result.exitCode != 0) {
        logger.err('$name: failed to run');
        return false;
      }
      final version = extractVersion(name, result.stdout.toString());
      logger.success('$name $version');
      return true;
    } on ProcessException {
      logger.err('$name: not found');
      return false;
    }
  }

  @visibleForTesting
  String extractVersion(String tool, String output) {
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
