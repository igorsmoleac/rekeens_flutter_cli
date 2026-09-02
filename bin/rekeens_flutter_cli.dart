import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:rekeens_flutter_cli/commands/config_command.dart';
import 'package:rekeens_flutter_cli/commands/create_command.dart';
import 'package:rekeens_flutter_cli/commands/doctor_command.dart';
import 'package:rekeens_flutter_cli/commands/generate_command.dart';
import 'package:rekeens_flutter_cli/commands/list_command.dart';
import 'package:rekeens_flutter_cli/utils/arg_preprocessor.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

void main(List<String> args) async {
  if (await handleVersionFlag(args)) {
    exit(0);
  }

  final runner =
      CommandRunner<void>(
          'rekeens',
          'A CLI tool for generating Flutter projects with custom architecture.',
        )
        ..addCommand(CreateCommand())
        ..addCommand(DoctorCommand())
        ..addCommand(GenerateCommand())
        ..addCommand(ConfigCommand())
        ..addCommand(ListCommand());

  try {
    await runner.run(expandAliases(args));
  } catch (e) {
    logger.err('$e');
    exit(64);
  }
}
