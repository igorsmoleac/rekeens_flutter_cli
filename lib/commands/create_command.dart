import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:rekeens_flutter_cli/services/prompter_service.dart';
import 'package:rekeens_flutter_cli/services/template_service.dart';
import 'package:rekeens_flutter_cli/services/project_file_writer.dart';
import 'package:rekeens_flutter_cli/utils/template_resolver.dart';
import 'package:rekeens_flutter_cli/utils/dependency_resolver.dart';
import 'package:rekeens_flutter_cli/config/presets.dart';
import 'package:rekeens_flutter_cli/config/config_loader.dart';

class CreateCommand extends Command<void> {
  final _templateService = const TemplateService();
  final _templateResolver = const TemplateResolver();
  final _prompter = const PrompterService();
  final _projectFileWriter = ProjectFileWriter();

  CreateCommand() {
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

    final options = _resolveOptions();

    print('Selected options:');
    options.forEach((key, value) => print('  $key: $value'));

    if (argResults!['dry-run'] as bool) {
      final dependencies = DependencyResolver.resolve(options);
      final devDependencies = DependencyResolver.resolveDevDependencies(
        includeCodegen: options['codegen'] as bool? ?? false,
      );
      print('\nDry run: no changes will be made.');
      print('Would create project "$projectName" with the above options.');
      if (dependencies.isNotEmpty) {
        print('Would add dependencies: ${dependencies.join(', ')}');
      } else {
        print('Would not add any dependencies.');
      }
      if (devDependencies.isNotEmpty) {
        print('Would add dev_dependencies: ${devDependencies.join(', ')}');
      }
      return;
    }

    print('Creating Flutter project "$projectName"...');
    await _runFlutterCreate(
      projectName,
      platforms: options['platforms'] as List<String>,
    );

    print('Applying custom template...');
    await _applyTemplate(projectName);

    print('Configuring project files...');
    await _projectFileWriter.configureProjectFiles(projectName, options);

    print('Adding dependencies...');
    final dependencies = DependencyResolver.resolve(options);
    await _addDependencies(projectName, dependencies);

    final codegen = options['codegen'] as bool? ?? false;
    if (codegen) {
      print('Adding dev_dependencies...');
      final devDependencies = DependencyResolver.resolveDevDependencies(
        includeCodegen: true,
      );
      await _addDependencies(projectName, devDependencies, dev: true);
    }

    if (options['localization'] == true) {
      print('Adding flutter_localizations...');
      await _runProcess('flutter', [
        'pub',
        'add',
        'flutter_localizations',
        '--sdk=flutter',
      ], workingDirectory: projectName);

      print('Enabling Flutter localization generation...');
      await _projectFileWriter.enableFlutterGenerate(projectName);

      print('Running pub get...');
      await _runProcess('flutter', [
        'pub',
        'get',
      ], workingDirectory: projectName);

      print('Generating localizations...');
      await _runProcess('flutter', ['gen-l10n'], workingDirectory: projectName);

      print('Running pub get after gen-l10n...');
      await _runProcess('flutter', [
        'pub',
        'get',
      ], workingDirectory: projectName);
    }

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
        args.wasParsed('theme') ||
        args.wasParsed('codegen');
  }

  Map<String, dynamic> _collectOptionsFromFlags() {
    final args = argResults!;
    final result = <String, dynamic>{};

    if (args.wasParsed('platforms')) {
      final platformsStr = args['platforms'] as String?;
      result['platforms'] = platformsStr != null
          ? platformsStr
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : <String>[];
    }
    if (args.wasParsed('architecture')) {
      result['architecture'] = args['architecture'];
    }
    if (args.wasParsed('state-management')) {
      result['state_management'] = args['state-management'];
    }
    if (args.wasParsed('router')) {
      result['router'] = args['router'];
    }
    if (args.wasParsed('networking')) {
      result['networking'] = args['networking'];
    }
    if (args.wasParsed('localization')) {
      result['localization'] = args['localization'];
    }
    if (args.wasParsed('theme')) {
      result['theme'] = args['theme'];
    }
    if (args.wasParsed('codegen')) {
      result['codegen'] = args['codegen'];
    }

    return result;
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

    final codegen = _prompter.askYesNo(
      'Add code generation tools (build_runner, freezed, json_serializable)?',
      defaultValue: false,
    );

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
      'codegen': codegen,
    };
  }

  Future<void> _applyTemplate(String projectName) async {
    final templateDir = await _templateResolver.resolve(category: 'base');
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
    List<String> packages, {
    bool dev = false,
  }) async {
    if (packages.isEmpty) return;
    final args = ['pub', 'add', if (dev) '--dev', ...packages];
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

    try {
      await _runProcess('flutter', args);
    } on Exception catch (e) {
      try {
        final projectDir = Directory(projectName);
        if (projectDir.existsSync()) {
          projectDir.deleteSync(recursive: true);
        }
      } catch (_) {}
      throw Exception(
        'Failed to create Flutter project "$projectName".\n'
        'Subsequent steps (template, dependencies, codegen) were skipped.\n'
        'Underlying error: $e',
      );
    }

    final projectDir = Directory(projectName);
    bool dirExists;
    try {
      dirExists = projectDir.existsSync();
    } catch (e) {
      throw Exception(
        'flutter create exited successfully but the project directory '
        '"$projectName" could not be accessed.\n'
        'Underlying error: $e',
      );
    }
    if (!dirExists) {
      throw Exception(
        'flutter create exited successfully but the project directory '
        '"$projectName" was not created. Aborting.',
      );
    }
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

  Map<String, dynamic> _resolveOptions() {
    final presetName = argResults!['preset'] as String?;
    if (presetName != null) {
      final preset = presets[presetName];
      if (preset == null) {
        throw UsageException(
          'Unknown preset "$presetName". Available: ${presets.keys.join(', ')}',
          usage,
        );
      }
      return _mergePresetWithFlags(preset);
    }

    final configOptions = ConfigLoader.load();
    final hasFlags = _hasAnyCreateFlag();

    if (hasFlags) {
      final flagOptions = _collectOptionsFromFlags();
      if (configOptions != null) {
        return {...configOptions, ...flagOptions};
      }
      return _fillDefaults(flagOptions);
    }

    if (configOptions != null) {
      return configOptions;
    }

    return _collectOptions();
  }

  Map<String, dynamic> _fillDefaults(Map<String, dynamic> partial) {
    return {
      'platforms':
          partial['platforms'] ?? ['android', 'ios', 'windows', 'linux'],
      'architecture': partial['architecture'] ?? 'feature-first',
      'state_management': partial['state_management'] ?? 'riverpod',
      'router': partial['router'] ?? 'go_router',
      'networking': partial['networking'] ?? 'dio',
      'localization': partial['localization'] ?? false,
      'theme': partial['theme'] ?? 'material3',
      'codegen': partial['codegen'] ?? false,
    };
  }

  Map<String, dynamic> _mergePresetWithFlags(Preset preset) {
    final options = preset.toOptions();
    final args = argResults!;

    if (args.wasParsed('platforms')) {
      final platformsStr = args['platforms'] as String?;
      options['platforms'] = platformsStr != null
          ? platformsStr
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : <String>[];
    }
    if (args.wasParsed('architecture')) {
      options['architecture'] = args['architecture'];
    }
    if (args.wasParsed('state-management')) {
      options['state_management'] = args['state-management'];
    }
    if (args.wasParsed('router')) {
      options['router'] = args['router'];
    }
    if (args.wasParsed('networking')) {
      options['networking'] = args['networking'];
    }
    if (args.wasParsed('localization')) {
      options['localization'] = args['localization'];
    }
    if (args.wasParsed('theme')) {
      options['theme'] = args['theme'];
    }
    if (args.wasParsed('codegen')) {
      options['codegen'] = args['codegen'];
    }

    return options;
  }
}
