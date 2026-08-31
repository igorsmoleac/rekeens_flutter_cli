import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/project_file_writer.dart';
import 'package:rekeens_flutter_cli/services/template_service.dart';
import 'package:rekeens_flutter_cli/utils/dependency_resolver.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';
import 'package:rekeens_flutter_cli/utils/template_resolver.dart';

typedef ScaffoldProcessRunner = Future<void> Function(
  String executable,
  List<String> args, {
  String? workingDirectory,
});

class ProjectScaffolder {
  ProjectScaffolder({
    TemplateService? templateService,
    TemplateResolver? templateResolver,
    ProjectFileWriter? projectFileWriter,
    ScaffoldProcessRunner? processRunner,
    Logger? log,
    String? workingDirectory,
  }) : _templateService = templateService ?? const TemplateService(),
       _templateResolver = templateResolver ?? const TemplateResolver(),
       _projectFileWriter =
           projectFileWriter ??
           ProjectFileWriter(workingDirectory: workingDirectory),
       _runProcess = processRunner ?? defaultScaffoldProcessRunner,
       _log = log ?? logger,
       _workingDirectory = workingDirectory;

  final TemplateService _templateService;
  final TemplateResolver _templateResolver;
  final ProjectFileWriter _projectFileWriter;
  final ScaffoldProcessRunner _runProcess;
  final Logger _log;
  final String? _workingDirectory;

  Future<void> scaffold(
    String projectName,
    Map<String, dynamic> options,
  ) async {
    final projectPath = _resolveProjectPath(projectName);
    await _createProject(
      projectName,
      projectPath,
      options['platforms'] as List<String>,
    );
    _log.info('Applying custom template...');
    await _applyTemplate(projectName, projectPath);
    _log.info('Configuring project files...');
    await _projectFileWriter.configureProjectFiles(projectPath, options);
    _log.info('Adding dependencies...');
    await _addDependencies(projectPath, DependencyResolver.resolve(options));
    await _addDevDependencies(projectPath, options);
    if (options['localization'] == true) {
      await _setupLocalization(projectPath);
    }
    _log.info('Formatting code...');
    await _runProcess('dart', ['format', '.'], workingDirectory: projectPath);
    _log.info('Running analyzer...');
    await _runProcess('flutter', ['analyze'], workingDirectory: projectPath);
  }

  String _resolveProjectPath(String projectName) {
    return _workingDirectory != null
        ? p.join(_workingDirectory, projectName)
        : projectName;
  }

  Future<void> _createProject(
    String projectName,
    String projectPath,
    List<String> platforms,
  ) async {
    final args = ['create'];
    if (platforms.isNotEmpty) {
      args.add('--platforms=${platforms.join(',')}');
    }
    args.add(projectName);

    try {
      await _runProcess('flutter', args);
    } on Exception catch (e) {
      try {
        final projectDir = Directory(projectPath);
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

    final projectDir = Directory(projectPath);
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

  Future<void> _applyTemplate(String projectName, String projectPath) async {
    final templateDir = await _templateResolver.resolve(
      category: 'base',
      workingDirectory: _workingDirectory,
    );
    await _templateService.copyTemplate(
      sourceDir: templateDir,
      targetDir: projectPath,
      variables: <String, String>{'project_name': projectName},
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

  Future<void> _addDevDependencies(
    String projectName,
    Map<String, dynamic> options,
  ) async {
    final codegen = options['codegen'] as bool? ?? false;
    if (!codegen) return;
    _log.info('Adding dev_dependencies...');
    final devDependencies = DependencyResolver.resolveDevDependencies(
      includeCodegen: true,
    );
    await _addDependencies(projectName, devDependencies, dev: true);
  }

  Future<void> _setupLocalization(String projectName) async {
    _log.info('Adding flutter_localizations...');
    await _runProcess('flutter', [
      'pub',
      'add',
      'flutter_localizations',
      '--sdk=flutter',
    ], workingDirectory: projectName);

    _log.info('Enabling Flutter localization generation...');
    await _projectFileWriter.enableFlutterGenerate(projectName);

    _log.info('Running pub get...');
    await _runProcess('flutter', ['pub', 'get'], workingDirectory: projectName);

    _log.info('Generating localizations...');
    await _runProcess('flutter', ['gen-l10n'], workingDirectory: projectName);

    _log.info('Running pub get after gen-l10n...');
    await _runProcess('flutter', ['pub', 'get'], workingDirectory: projectName);
  }
}

Future<void> defaultScaffoldProcessRunner(
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
