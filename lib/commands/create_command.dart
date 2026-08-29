import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/prompter_service.dart';
import 'package:rekeens_flutter_cli/services/template_service.dart';
import 'package:rekeens_flutter_cli/utils/project_paths.dart';
import 'package:rekeens_flutter_cli/utils/dependency_resolver.dart';
import 'package:rekeens_flutter_cli/config/presets.dart';
import 'package:rekeens_flutter_cli/config/config_loader.dart';

class CreateCommand extends Command<void> {
  final _templateService = const TemplateService();
  final _prompter = const PrompterService();

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

    print('Creating Flutter project "$projectName"...');
    await _runFlutterCreate(
      projectName,
      platforms: options['platforms'] as List<String>,
    );

    print('Applying custom template...');
    await _applyTemplate(projectName);

    print('Configuring project files...');
    await _configureProjectFiles(projectName, options);

    print('Adding dependencies...');
    final dependencies = DependencyResolver.resolve(options);
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

  Future<void> _configureProjectFiles(
    String projectName,
    Map<String, dynamic> options,
  ) async {
    final stateManagement = options['state_management'] as String;
    final router = options['router'] as String;
    final theme = options['theme'] as String;

    await _writeMainDart(projectName, stateManagement: stateManagement);
    await _writeAppDart(
      projectName,
      title: projectName,
      useGoRouter: router == 'go_router',
      useMaterial3: theme == 'material3',
    );
    await _writeRouterDart(projectName, useGoRouter: router == 'go_router');
  }

  Future<void> _writeMainDart(
    String projectName, {
    required String stateManagement,
  }) async {
    final mainFile = File(p.join(projectName, 'lib', 'main.dart'));
    final useRiverpod = stateManagement == 'riverpod';
    final buffer = StringBuffer();

    buffer.writeln("import 'package:flutter/material.dart';");
    if (useRiverpod) {
      buffer.writeln(
        "import 'package:flutter_riverpod/flutter_riverpod.dart';",
      );
    }
    buffer.writeln("import 'app/app.dart';");
    buffer.writeln();
    buffer.writeln('void main() {');
    if (useRiverpod) {
      buffer.writeln('  runApp(const ProviderScope(child: App()));');
    } else {
      buffer.writeln('  runApp(const App());');
    }
    buffer.writeln('}');

    await mainFile.writeAsString(buffer.toString());
  }

  Future<void> _writeAppDart(
    String projectName, {
    required String title,
    required bool useGoRouter,
    required bool useMaterial3,
  }) async {
    final appFile = File(p.join(projectName, 'lib', 'app', 'app.dart'));
    final buffer = StringBuffer();

    buffer.writeln("import 'package:flutter/material.dart';");
    if (useGoRouter) {
      buffer.writeln("import 'router.dart';");
    } else {
      buffer.writeln(
        "import '../features/home/presentation/pages/home_page.dart';",
      );
    }
    buffer.writeln();
    buffer.writeln('class App extends StatelessWidget {');
    buffer.writeln('  const App({super.key});');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    return MaterialApp${useGoRouter ? '.router' : ''}(');
    buffer.writeln("      title: '$title',");
    buffer.writeln('      theme: ThemeData(');
    buffer.writeln('        useMaterial3: $useMaterial3,');
    if (useMaterial3) {
      buffer.writeln(
        '        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),',
      );
    } else {
      buffer.writeln('        primarySwatch: Colors.blue,');
    }
    buffer.writeln('      ),');
    if (useGoRouter) {
      buffer.writeln('      routerConfig: appRouter,');
    } else {
      buffer.writeln('      home: const HomePage(),');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');

    await appFile.writeAsString(buffer.toString());
  }

  Future<void> _writeRouterDart(
    String projectName, {
    required bool useGoRouter,
  }) async {
    final routerFile = File(p.join(projectName, 'lib', 'app', 'router.dart'));
    final buffer = StringBuffer();

    if (useGoRouter) {
      buffer.writeln("import 'package:go_router/go_router.dart';");
      buffer.writeln(
        "import '../features/home/presentation/pages/home_page.dart';",
      );
      buffer.writeln();
      buffer.writeln('final appRouter = GoRouter(');
      buffer.writeln('  routes: [');
      buffer.writeln('    GoRoute(');
      buffer.writeln("      path: '/',");
      buffer.writeln('      builder: (context, state) => const HomePage(),');
      buffer.writeln('    ),');
      buffer.writeln('  ],');
      buffer.writeln(');');
    } else {
      buffer.writeln('class AppRouter {');
      buffer.writeln("  static const String home = '/';");
      buffer.writeln('}');
    }

    await routerFile.writeAsString(buffer.toString());
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

    if (_hasAnyCreateFlag()) {
      return _collectOptionsFromFlags();
    }

    final configOptions = ConfigLoader.load();
    if (configOptions != null) {
      return configOptions;
    }

    return _collectOptions();
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

    return options;
  }
}
