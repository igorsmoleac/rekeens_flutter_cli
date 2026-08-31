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

    await _renderBootstrapFile(
      bootstrapDir: bootstrapDir,
      fileName: 'main.dart',
      targetPath: p.join(projectName, 'lib', 'main.dart'),
      variables: variables,
      conditions: conditions,
    );

    if (stateManagement == 'bloc') {
      await _renderBootstrapFile(
        bootstrapDir: bootstrapDir,
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

      await _renderBootstrapFile(
        bootstrapDir: bootstrapDir,
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

    await _renderBootstrapFile(
      bootstrapDir: bootstrapDir,
      fileName: 'app.dart',
      targetPath: p.join(projectName, 'lib', 'app', 'app.dart'),
      variables: variables,
      conditions: conditions,
    );

    await _renderBootstrapFile(
      bootstrapDir: bootstrapDir,
      fileName: 'router.dart',
      targetPath: p.join(projectName, 'lib', 'app', 'router.dart'),
      variables: variables,
      conditions: conditions,
    );

    if (localization) {
      await _renderBootstrapFile(
        bootstrapDir: bootstrapDir,
        fileName: 'l10n.yaml',
        targetPath: p.join(projectName, 'l10n.yaml'),
        variables: variables,
        conditions: conditions,
      );

      Directory(p.join(projectName, 'lib', 'l10n')).createSync(recursive: true);
      await _renderBootstrapFile(
        bootstrapDir: bootstrapDir,
        fileName: 'app_en.arb',
        targetPath: p.join(projectName, 'lib', 'l10n', 'app_en.arb'),
        variables: variables,
        conditions: conditions,
      );
    }
  }

  Future<void> _renderBootstrapFile({
    required String bootstrapDir,
    required String fileName,
    required String targetPath,
    required Map<String, String> variables,
    required Map<String, bool> conditions,
  }) async {
    await _templateService.renderFile(
      sourcePath: p.join(bootstrapDir, fileName),
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
