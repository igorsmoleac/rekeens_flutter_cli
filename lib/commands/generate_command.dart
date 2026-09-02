import 'package:args/command_runner.dart';
import 'package:rekeens_flutter_cli/config/config_loader.dart';
import 'package:rekeens_flutter_cli/config/hooks.dart';
import 'package:rekeens_flutter_cli/generators/datasource_generator.dart';
import 'package:rekeens_flutter_cli/generators/entity_generator.dart';
import 'package:rekeens_flutter_cli/generators/feature_generator.dart';
import 'package:rekeens_flutter_cli/generators/model_generator.dart';
import 'package:rekeens_flutter_cli/generators/provider_generator.dart';
import 'package:rekeens_flutter_cli/generators/repository_generator.dart';
import 'package:rekeens_flutter_cli/generators/screen_generator.dart';
import 'package:rekeens_flutter_cli/generators/service_generator.dart';
import 'package:rekeens_flutter_cli/generators/usecase_generator.dart';

class GenerateCommand extends Command<void> {
  GenerateCommand({HookRunner? hookRunner, String? workingDirectory})
    : _hookRunner =
          hookRunner ?? HookRunner(workingDirectory: workingDirectory),
      _workingDirectory = workingDirectory {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Overwrite existing files.',
      defaultsTo: false,
    );
    argParser.addFlag(
      'dry-run',
      abbr: 'n',
      help: 'Print planned actions without writing any files.',
      defaultsTo: false,
      negatable: false,
    );
    argParser.addFlag(
      'tests',
      help: 'Generate unit/widget test stubs alongside the component.',
      defaultsTo: true,
    );
    argParser.addFlag(
      'hooks',
      help: 'Run before/after generate hooks from rekeens.yaml.',
      defaultsTo: true,
    );
    argParser.addOption(
      'base-url',
      help:
          'Base URL for datasource templates (e.g. https://api.example.com). '
          'Falls back to rekeens.yaml `defaults.base-url`.',
    );
  }
  final HookRunner _hookRunner;
  final String? _workingDirectory;

  final _featureGenerator = FeatureGenerator();
  final _screenGenerator = ScreenGenerator();
  final _modelGenerator = ModelGenerator();
  final _repositoryGenerator = RepositoryGenerator();
  final _serviceGenerator = ServiceGenerator();
  final _providerGenerator = ProviderGenerator();
  final _entityGenerator = EntityGenerator();
  final _useCaseGenerator = UseCaseGenerator();
  final _datasourceGenerator = DatasourceGenerator();

  @override
  String get name => 'generate';

  @override
  String get description => 'Generate features, screens, models, etc.';

  @override
  String get invocation => 'rekeens generate <type> <name>';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length < 2) {
      throw UsageException('Expected: rekeens generate <type> <name>', usage);
    }

    final type = rest[0];
    final force = argResults!['force'] as bool;
    final dryRun = argResults!['dry-run'] as bool;
    final withTests = argResults!['tests'] as bool;
    final hooksEnabled = argResults!['hooks'] as bool;

    final featureName = rest[1];
    final entityName = rest.length > 2 ? rest[2] : null;

    final hookSet = hooksEnabled
        ? ConfigLoader.loadHooks(workingDirectory: _workingDirectory)
        : const HookSet();

    final context = HookContext(
      generatorType: type,
      featureName: featureName,
      entityName: entityName,
      dryRun: dryRun,
    );

    if (hooksEnabled && hookSet.beforeGenerate.isNotEmpty) {
      await _hookRunner.runHooks(hookSet.beforeGenerate, context);
    }

    await _runGenerator(type, rest, force, dryRun, withTests);

    if (hooksEnabled && hookSet.afterGenerate.isNotEmpty) {
      await _hookRunner.runHooks(hookSet.afterGenerate, context);
    }
  }

  Future<void> _runGenerator(
    String type,
    List<String> rest,
    bool force,
    bool dryRun,
    bool withTests,
  ) async {
    switch (type) {
      case 'feature':
        await _featureGenerator.generate(
          rest[1],
          force: force,
          dryRun: dryRun,
          withTests: withTests,
        );
        break;
      case 'screen':
        _validateLength(
          rest,
          3,
          'rekeens generate screen <feature_name> <screen_name>',
        );
        await _screenGenerator.generate(
          rest[1],
          rest[2],
          force: force,
          dryRun: dryRun,
          withTests: withTests,
        );
        break;
      case 'model':
        _validateLength(
          rest,
          3,
          'rekeens generate model <feature_name> <model_name> [field:type ...]',
        );
        await _modelGenerator.generate(
          rest[1],
          rest[2],
          fields: rest.length > 3 ? rest.sublist(3) : null,
          force: force,
          dryRun: dryRun,
          withTests: withTests,
        );
        break;
      case 'repository':
        _validateLength(
          rest,
          3,
          'rekeens generate repository <feature_name> <repository_name>',
        );
        await _repositoryGenerator.generate(
          rest[1],
          rest[2],
          force: force,
          dryRun: dryRun,
          withTests: withTests,
        );
        break;
      case 'service':
        _validateLength(
          rest,
          3,
          'rekeens generate service <feature_name> <service_name>',
        );
        await _serviceGenerator.generate(
          rest[1],
          rest[2],
          force: force,
          dryRun: dryRun,
          withTests: withTests,
        );
        break;
      case 'provider':
        _validateLength(
          rest,
          3,
          'rekeens generate provider <feature_name> <provider_name>',
        );
        await _providerGenerator.generate(
          rest[1],
          rest[2],
          force: force,
          dryRun: dryRun,
          withTests: withTests,
        );
        break;
      case 'entity':
        _validateLength(
          rest,
          3,
          'rekeens generate entity <feature_name> <entity_name>',
        );
        await _entityGenerator.generate(
          rest[1],
          rest[2],
          force: force,
          dryRun: dryRun,
          withTests: withTests,
        );
        break;
      case 'usecase':
        _validateLength(
          rest,
          3,
          'rekeens generate usecase <feature_name> <usecase_name>',
        );
        await _useCaseGenerator.generate(
          rest[1],
          rest[2],
          force: force,
          dryRun: dryRun,
          withTests: withTests,
        );
        break;
      case 'datasource':
        _validateLength(
          rest,
          3,
          'rekeens generate datasource <feature_name> <datasource_name>',
        );
        final baseUrl = _resolveBaseUrl();
        await _datasourceGenerator.generate(
          rest[1],
          rest[2],
          baseUrl: baseUrl,
          force: force,
          dryRun: dryRun,
          withTests: withTests,
        );
        break;
      default:
        throw UsageException(
          'Unknown generator type "$type". Available: feature, screen, model, repository, service, provider, entity, usecase, datasource',
          usage,
        );
    }
  }

  void _validateLength(List<String> args, int expected, String usage) {
    if (args.length < expected) {
      throw UsageException('Expected: $usage', usage);
    }
  }

  /// Resolves the datasource base URL from (in priority order):
  /// 1. `--base-url` CLI flag
  /// 2. `rekeens.yaml` `defaults.base-url`
  /// 3. `null` (the generator will use its built-in placeholder)
  String? _resolveBaseUrl() {
    final flagValue = argResults!['base-url'] as String?;
    if (flagValue != null && flagValue.isNotEmpty) return flagValue;

    final config = ConfigLoader.load(workingDirectory: _workingDirectory);
    final configValue = config?['base-url'];
    if (configValue is String && configValue.isNotEmpty) return configValue;

    return null;
  }
}
