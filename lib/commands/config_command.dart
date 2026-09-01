import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/utils/logger.dart';

class ConfigCommand extends Command<void> {
  ConfigCommand({String? workingDirectory}) {
    addSubcommand(ConfigInitCommand(workingDirectory: workingDirectory));
  }

  @override
  String get name => 'config';

  @override
  String get description => 'Manage rekeens configuration.';

  @override
  String get invocation => 'rekeens config <subcommand> [options]';
}

class ConfigInitCommand extends Command<void> {
  ConfigInitCommand({this.workingDirectory}) {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Overwrite an existing rekeens.yaml.',
      defaultsTo: false,
    );
    argParser.addFlag(
      'dry-run',
      abbr: 'n',
      help: 'Print the planned action without writing the file.',
      defaultsTo: false,
      negatable: false,
    );
  }
  final String? workingDirectory;

  @override
  String get name => 'init';

  @override
  String get description => 'Generate a rekeens.yaml with default settings.';

  @override
  String get invocation => 'rekeens config init [options]';

  @override
  Future<void> run() async {
    final dir = workingDirectory ?? Directory.current.path;
    final configPath = p.join(dir, 'rekeens.yaml');
    final force = argResults!['force'] as bool;
    final dryRun = argResults!['dry-run'] as bool;

    if (File(configPath).existsSync() && !force) {
      throw UsageException(
        'rekeens.yaml already exists at $configPath. Use --force to overwrite.',
        usage,
      );
    }

    if (dryRun) {
      logger.warn('DRY RUN: would write rekeens.yaml -> $configPath');
      return;
    }

    File(configPath).writeAsStringSync(defaultConfigContent);
    logger.success('Created rekeens.yaml at $configPath');
  }

  @visibleForTesting
  static const String defaultConfigContent = '''
defaults:
  platforms:
    - android
    - ios
    - windows
    - linux
  architecture: feature-first
  state_management: riverpod
  router: go_router
  networking: dio
  storage: shared_preferences
  localization: false
  theme: material3
  seed_color: "0xFF2196F3"
  font_family: ''
  codegen: false
  pin_versions: false

# Custom analysis_options.yaml for generated projects.
# Uncomment and adapt to enforce your team's linting standards.
# analysis_options:
#   include: package:flutter_lints/flutter.yaml
#   analyzer:
#     language:
#       strict-casts: true
#       strict-raw-types: true
#     errors:
#       todo: ignore
#   linter:
#     rules:
#       prefer_const_constructors: true
#       prefer_const_declarations: true
#       avoid_print: true
#       require_trailing_commas: true
''';
}
