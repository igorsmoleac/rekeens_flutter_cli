import 'package:args/command_runner.dart';
import 'package:rekeens_flutter_cli/services/options_resolver.dart';
import 'package:rekeens_flutter_cli/services/project_scaffolder.dart';
import 'package:rekeens_flutter_cli/utils/dependency_resolver.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

class CreateCommand extends Command<void> {
  CreateCommand({
    OptionsResolver? optionsResolver,
    ProjectScaffolder? scaffolder,
  }) : _optionsResolver = optionsResolver ?? OptionsResolver(),
       _scaffolder = scaffolder ?? ProjectScaffolder() {
    argParser.addOption(
      'preset',
      help: 'Use a preset configuration (minimal, mobile, full)',
    );
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Enable verbose output.',
      defaultsTo: false,
    );
    argParser.addFlag(
      'dry-run',
      abbr: 'n',
      help: 'Show what would be done without making changes.',
      defaultsTo: false,
    );
    argParser.addFlag(
      'codegen',
      help: 'Add build_runner, freezed, json_serializable as dev dependencies.',
      defaultsTo: false,
    );
    argParser.addOption(
      'platforms',
      help: 'Comma-separated list: android,ios,windows,linux,macos,web',
    );
    argParser.addOption(
      'architecture',
      help: 'Architecture type (feature-first)',
    );
    argParser.addOption(
      'state-management',
      help: 'State management (riverpod, bloc, none)',
    );
    argParser.addOption('router', help: 'Router (go_router, none)');
    argParser.addOption('networking', help: 'Networking (dio, http, none)');
    argParser.addFlag(
      'localization',
      help: 'Enable localization',
      defaultsTo: false,
    );
    argParser.addOption('theme', help: 'Theme (material3, material2)');
  }

  final OptionsResolver _optionsResolver;
  final ProjectScaffolder _scaffolder;

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Flutter project with custom setup.';

  @override
  String get invocation => 'rekeens create <project_name> [options]';

  @override
  Future<void> run() async {
    final projectName = _readProjectName();
    final options = _optionsResolver.resolve(argResults!, usage: usage);

    logger.info('Selected options:');
    options.forEach((key, value) => logger.detail('  $key: $value'));

    if (argResults!['dry-run'] as bool) {
      _printDryRun(projectName, options);
      return;
    }

    logger.info('Creating Flutter project "$projectName"...');
    await _scaffolder.scaffold(projectName, options);
    logger.success('Project created successfully.');
  }

  String _readProjectName() {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      throw UsageException('Project name is required.', usage);
    }
    if (rest.length > 1) {
      throw UsageException(
        'Too many arguments. Expected only one project name.',
        usage,
      );
    }

    final projectName = rest.first;
    if (!_isValidProjectName(projectName)) {
      throw UsageException(
        'Invalid project name "$projectName".\n'
        'Project name must start with a lowercase letter or underscore, '
        'and contain only lowercase letters, digits, and underscores.',
        usage,
      );
    }

    final verbose = argResults!['verbose'] as bool;
    if (verbose) {
      logger.detail('Verbose mode enabled.');
    }

    return projectName;
  }

  void _printDryRun(String projectName, Map<String, dynamic> options) {
    final dependencies = DependencyResolver.resolve(options);
    final devDependencies = DependencyResolver.resolveDevDependencies(
      includeCodegen: options['codegen'] as bool? ?? false,
    );
    logger.info('');
    logger.info('Dry run: no changes will be made.');
    logger.info('Would create project "$projectName" with the above options.');
    if (dependencies.isNotEmpty) {
      logger.info('Would add dependencies: ${dependencies.join(', ')}');
    } else {
      logger.info('Would not add any dependencies.');
    }
    if (devDependencies.isNotEmpty) {
      logger.info('Would add dev_dependencies: ${devDependencies.join(', ')}');
    }
  }

  bool _isValidProjectName(String name) {
    final regex = RegExp(r'^[a-z_][a-z0-9_]*$');
    return regex.hasMatch(name);
  }
}
