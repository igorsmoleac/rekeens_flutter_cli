import 'package:args/command_runner.dart';
import 'package:rekeens_flutter_cli/generators/feature_generator.dart';
import 'package:rekeens_flutter_cli/generators/model_generator.dart';
import 'package:rekeens_flutter_cli/generators/provider_generator.dart';
import 'package:rekeens_flutter_cli/generators/repository_generator.dart';
import 'package:rekeens_flutter_cli/generators/screen_generator.dart';
import 'package:rekeens_flutter_cli/generators/service_generator.dart';

class GenerateCommand extends Command<void> {
  GenerateCommand() {
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
  }
  final _featureGenerator = FeatureGenerator();
  final _screenGenerator = ScreenGenerator();
  final _modelGenerator = ModelGenerator();
  final _repositoryGenerator = RepositoryGenerator();
  final _serviceGenerator = ServiceGenerator();
  final _providerGenerator = ProviderGenerator();

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

    switch (type) {
      case 'feature':
        await _featureGenerator.generate(rest[1], force: force, dryRun: dryRun);
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
        );
        break;
      default:
        throw UsageException(
          'Unknown generator type "$type". Available: feature, screen, model, repository, service, provider',
          usage,
        );
    }
  }

  void _validateLength(List<String> args, int expected, String usage) {
    if (args.length < expected) {
      throw UsageException('Expected: $usage', usage);
    }
  }
}
