import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/prompter_service.dart';
import 'package:rekeens_flutter_cli/services/template_service.dart';
import 'package:rekeens_flutter_cli/utils/project_paths.dart';

class CreateCommand extends Command<void> {
  final _templateService = const TemplateService();
  final _prompter = const PrompterService();

  CreateCommand() {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Enable verbose output.',
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

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Flutter project with custom setup.';

  @override
  String get invocation => 'rekeens create <project_name> [options]';

  @override
  Future<void> run() async {
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
      print('Verbose mode enabled.');
    }

    final options = _hasAnyCreateFlag()
        ? _collectOptionsFromFlags()
        : _collectOptions();

    print('Selected options:');
    options.forEach((key, value) => print('  $key: $value'));

    print('Creating Flutter project "$projectName"...');
    await _runFlutterCreate(
      projectName,
      platforms: options['platforms'] as List<String>,
    );

    print('Applying custom template...');
    await _applyTemplate(projectName);

    print('Adding dependencies...');
    final dependencies = _getDependencies(options);
    await _addDependencies(projectName, dependencies);

    print('Formatting code...');
    await _runProcess('dart', ['format', '.'], workingDirectory: projectName);

    print('Running analyzer...');
    await _runProcess('flutter', ['analyze'], workingDirectory: projectName);

    print('Project created successfully.');
  }

  bool _hasAnyCreateFlag() {
    final args = argResults!;
    return args.wasParsed('platforms') ||
        args.wasParsed('architecture') ||
        args.wasParsed('state-management') ||
        args.wasParsed('router') ||
        args.wasParsed('networking') ||
        args.wasParsed('localization') ||
        args.wasParsed('theme');
  }

  Map<String, dynamic> _collectOptionsFromFlags() {
    final args = argResults!;

    final platformsStr = args['platforms'] as String?;
    final platforms = platformsStr != null
        ? platformsStr
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];

    final localization = args['localization'] as bool;

    return {
      'platforms': platforms,
      'architecture': args['architecture'] ?? 'feature-first',
      'state_management': args['state-management'] ?? 'riverpod',
      'router': args['router'] ?? 'go_router',
      'networking': args['networking'] ?? 'dio',
      'localization': localization,
      'theme': args['theme'] ?? 'material3',
    };
  }

  Map<String, dynamic> _collectOptions() {
    final selectedPlatforms = _prompter.askMultipleChoice(
      'Select platforms',
      ['android', 'ios', 'windows', 'linux', 'macos', 'web'],
      defaults: ['android', 'ios', 'windows', 'linux'],
    );

    final architecture = _prompter.askChoice('Architecture', [
      'feature-first',
    ], defaultValue: 'feature-first');

    final stateManagement = _prompter.askChoice('State management', [
      'riverpod',
      'bloc',
      'none',
    ], defaultValue: 'riverpod');

    final router = _prompter.askChoice('Routing', [
      'go_router',
      'none',
    ], defaultValue: 'go_router');

    final networking = _prompter.askChoice('Networking', [
      'dio',
      'http',
      'none',
    ], defaultValue: 'dio');

    final localization = _prompter.askYesNo('Localization', defaultValue: true);
    final theme = _prompter.askChoice('Theme', [
      'material3',
      'material2',
    ], defaultValue: 'material3');

    return {
      'platforms': selectedPlatforms,
      'architecture': architecture,
      'state_management': stateManagement,
      'router': router,
      'networking': networking,
      'localization': localization,
      'theme': theme,
    };
  }

  List<String> _getDependencies(Map<String, dynamic> options) {
    final deps = <String>[];

    final stateManagement = options['state_management'] as String;
    final router = options['router'] as String;
    final networking = options['networking'] as String;
    final localization = options['localization'] as bool;

    switch (stateManagement) {
      case 'riverpod':
        deps.add('flutter_riverpod');
        break;
      case 'bloc':
        deps.add('flutter_bloc');
        break;
      default:
        break;
    }

    switch (router) {
      case 'go_router':
        deps.add('go_router');
        break;
      default:
        break;
    }

    switch (networking) {
      case 'dio':
        deps.add('dio');
        break;
      case 'http':
        deps.add('http');
        break;
      default:
        break;
    }

    if (localization) {
      deps.add('intl');
    }

    return deps;
  }

  Future<void> _applyTemplate(String projectName) async {
    final templateDir = p.join(getPackageRoot(), 'templates', 'base');
    final targetDir = projectName;

    final variables = <String, String>{'project_name': projectName};

    await _templateService.copyTemplate(
      sourceDir: templateDir,
      targetDir: targetDir,
      variables: variables,
    );
  }

  Future<void> _addDependencies(
    String projectName,
    List<String> packages,
  ) async {
    if (packages.isEmpty) return;
    final args = ['pub', 'add', ...packages];
    await _runProcess('flutter', args, workingDirectory: projectName);
  }

  Future<void> _runFlutterCreate(
    String projectName, {
    List<String> platforms = const [],
  }) async {
    final args = ['create'];
    if (platforms.isNotEmpty) {
      args.add('--platforms=${platforms.join(',')}');
    }
    args.add(projectName);
    await _runProcess('flutter', args);
  }

  Future<void> _runProcess(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) async {
    try {
      Process process;
      if (Platform.isWindows) {
        process = await Process.start('cmd', [
          '/c',
          executable,
          ...args,
        ], workingDirectory: workingDirectory);
      } else {
        process = await Process.start(
          executable,
          args,
          workingDirectory: workingDirectory,
        );
      }

      await Future.wait([
        stdout.addStream(process.stdout),
        stderr.addStream(process.stderr),
      ]);

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        throw Exception(
          '$executable ${args.join(' ')} failed with exit code $exitCode',
        );
      }
    } on ProcessException catch (e) {
      throw Exception(
        'Unable to run $executable. Make sure it is installed and added to PATH.\n'
        'Error: ${e.message}',
      );
    }
  }

  bool _isValidProjectName(String name) {
    final regex = RegExp(r'^[a-z_][a-z0-9_]*$');
    return regex.hasMatch(name);
  }
}
