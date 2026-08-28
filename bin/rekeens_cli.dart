import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:rekeens_flutter_cli/commands/create_command.dart';
import 'package:rekeens_flutter_cli/commands/doctor_command.dart';
import 'package:rekeens_flutter_cli/commands/generate_command.dart';

void main(List<String> args) {
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

  runner.run(args).catchError((error) {
    stderr.writeln(error);
    exit(64);
  });
}
