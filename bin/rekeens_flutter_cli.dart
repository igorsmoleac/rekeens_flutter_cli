import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:rekeens_flutter_cli/commands/create_command.dart';
import 'package:rekeens_flutter_cli/commands/doctor_command.dart';
import 'package:rekeens_flutter_cli/commands/generate_command.dart';
import 'package:rekeens_flutter_cli/utils/app_version.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

void main(List<String> args) async {
  if (args.contains('--version') || args.contains('-v')) {
    logger.info(await getAppVersion());
    exit(0);
  }

  if (args.isNotEmpty && args.first == 'g') {
    args[0] = 'generate';
  }

  final runner =
      CommandRunner<void>(
          'rekeens',
          'A CLI tool for generating Flutter projects with custom architecture.',
        )
        ..addCommand(CreateCommand())
        ..addCommand(DoctorCommand())
        ..addCommand(GenerateCommand());

  try {
    await runner.run(args);
  } catch (e) {
    logger.err('$e');
    exit(64);
  }
}
