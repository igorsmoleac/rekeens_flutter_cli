import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/template_service.dart';
import 'package:rekeens_flutter_cli/utils/template_resolver.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

class ProjectFileWriter {
  ProjectFileWriter({
    TemplateService? templateService,
    TemplateResolver? templateResolver,
    this.workingDirectory,
    this.templatesRootOverride,
  }) : _templateService = templateService ?? const TemplateService(),
       _templateResolver = templateResolver ?? const TemplateResolver();

  final TemplateService _templateService;
  final TemplateResolver _templateResolver;
  final String? workingDirectory;
  final String? templatesRootOverride;

  Future<void> configureProjectFiles(
    String projectName,
    Map<String, dynamic> options,
  ) async {
    final stateManagement = options['state_management'] as String;
    final router = options['router'] as String;
    final theme = options['theme'] as String;
    final networking = options['networking'] as String? ?? 'none';
    final localization = options['localization'] as bool? ?? false;

    final bootstrapDir = await _templateResolver.resolve(
      category: 'bootstrap',
      workingDirectory: workingDirectory,
      packageRootOverride: templatesRootOverride,
    );

    final variables = <String, String>{'project_name': projectName};
    final conditions = <String, bool>{
      'riverpod': stateManagement == 'riverpod',
      'bloc': stateManagement == 'bloc',
      'none': stateManagement == 'none',
      'go_router': router == 'go_router',
      'material3': theme == 'material3',
      'l10n': localization,
    };

    await _renderTemplateFile(
      sourceDir: bootstrapDir,
      fileName: 'main.dart',
      targetPath: p.join(projectName, 'lib', 'main.dart'),
      variables: variables,
      conditions: conditions,
    );

    if (stateManagement == 'bloc') {
      await _renderTemplateFile(
        sourceDir: bootstrapDir,
        fileName: 'app_state.dart',
        targetPath: p.join(
          projectName,
          'lib',
          'core',
          'state',
          'app_state.dart',
        ),
        variables: variables,
        conditions: conditions,
      );

      await _renderTemplateFile(
        sourceDir: bootstrapDir,
        fileName: 'app_cubit.dart',
        targetPath: p.join(
          projectName,
          'lib',
          'core',
          'state',
          'app_cubit.dart',
        ),
        variables: variables,
        conditions: conditions,
      );
    }

    await _renderTemplateFile(
      sourceDir: bootstrapDir,
      fileName: 'app.dart',
      targetPath: p.join(projectName, 'lib', 'app', 'app.dart'),
      variables: variables,
      conditions: conditions,
    );

    await _renderTemplateFile(
      sourceDir: bootstrapDir,
      fileName: 'router.dart',
      targetPath: p.join(projectName, 'lib', 'app', 'router.dart'),
      variables: variables,
      conditions: conditions,
    );

    if (networking != 'none') {
      await _renderNetworkFiles(projectName, networking);
    }

    if (localization) {
      await _renderTemplateFile(
        sourceDir: bootstrapDir,
        fileName: 'l10n.yaml',
        targetPath: p.join(projectName, 'l10n.yaml'),
        variables: variables,
        conditions: conditions,
      );

      Directory(p.join(projectName, 'lib', 'l10n')).createSync(recursive: true);
      await _renderTemplateFile(
        sourceDir: bootstrapDir,
        fileName: 'app_en.arb',
        targetPath: p.join(projectName, 'lib', 'l10n', 'app_en.arb'),
        variables: variables,
        conditions: conditions,
      );
    }
  }

  Future<void> _renderNetworkFiles(
    String projectName,
    String networking,
  ) async {
    final coreDir = await _templateResolver.resolve(
      category: 'core',
      workingDirectory: workingDirectory,
      packageRootOverride: templatesRootOverride,
    );

    final networkDir = p.join(projectName, 'lib', 'core', 'network');
    const variables = <String, String>{};
    const conditions = <String, bool>{};

    await _renderTemplateFile(
      sourceDir: coreDir,
      fileName: 'network_config.dart',
      targetPath: p.join(networkDir, 'network_config.dart'),
      variables: variables,
      conditions: conditions,
    );

    await _renderTemplateFile(
      sourceDir: coreDir,
      fileName: 'api_exception.dart',
      targetPath: p.join(networkDir, 'api_exception.dart'),
      variables: variables,
      conditions: conditions,
    );

    final clientFile = networking == 'dio'
        ? 'dio_client.dart'
        : 'http_client.dart';
    await _renderTemplateFile(
      sourceDir: coreDir,
      fileName: clientFile,
      targetPath: p.join(networkDir, clientFile),
      variables: variables,
      conditions: conditions,
    );
  }

  Future<void> _renderTemplateFile({
    required String sourceDir,
    required String fileName,
    required String targetPath,
    required Map<String, String> variables,
    required Map<String, bool> conditions,
  }) async {
    await _templateService.renderFile(
      sourcePath: p.join(sourceDir, fileName),
      targetPath: targetPath,
      variables: variables,
      conditions: conditions,
    );
  }

  Future<void> enableFlutterGenerate(String projectName) async {
    final pubspecFile = File(p.join(projectName, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return;

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content) as YamlMap;

    final flutter = yaml['flutter'];
    if (flutter is YamlMap && flutter['generate'] == true) return;

    final editor = YamlEditor(content);
    if (flutter is YamlMap) {
      editor.update(['flutter', 'generate'], true);
    } else {
      editor.update(['flutter'], {'generate': true});
    }

    await pubspecFile.writeAsString(editor.toString());
  }
}
