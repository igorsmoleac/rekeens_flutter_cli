import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:rekeens_flutter_cli/config/presets.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

class ListCommand extends Command<void> {
  ListCommand({Logger? log}) : log = log ?? logger;
  final Logger log;

  @override
  String get name => 'list';

  @override
  String get description => 'List available presets and generators.';

  @override
  String get invocation => 'rekeens list';

  @override
  Future<void> run() async {
    _printPresets();
    log.info('');
    _printGenerators();
  }

  void _printPresets() {
    log.info(lightYellow.wrap('Presets')!);
    for (final entry in presets.entries) {
      final p = entry.value;
      log.info('  ${lightCyan.wrap(p.name)}');
      log.info(
        '    platforms: ${p.platforms.join(', ')} | '
        'state: ${p.stateManagement} | router: ${p.router} | '
        'networking: ${p.networking} | theme: ${p.theme} | '
        'l10n: ${p.localization} | codegen: ${p.codegen}',
      );
    }
  }

  void _printGenerators() {
    log.info(lightYellow.wrap('Generators')!);
    for (final g in generators) {
      log.info('  ${lightCyan.wrap(g.name)}');
      log.info('    ${g.description}');
      log.info('    example: ${g.example}');
    }
  }
}

class GeneratorInfo {
  const GeneratorInfo({
    required this.name,
    required this.description,
    required this.example,
  });
  final String name;
  final String description;
  final String example;
}

const generators = <GeneratorInfo>[
  GeneratorInfo(
    name: 'feature',
    description: 'Create a new feature directory structure.',
    example: 'rekeens generate feature auth',
  ),
  GeneratorInfo(
    name: 'screen',
    description: 'Create a screen inside a feature.',
    example: 'rekeens generate screen auth login',
  ),
  GeneratorInfo(
    name: 'model',
    description: 'Create a data model with optional fields (name:type ...).',
    example: 'rekeens generate model auth user name:string age:int',
  ),
  GeneratorInfo(
    name: 'repository',
    description: 'Create a repository inside a feature.',
    example: 'rekeens generate repository auth user',
  ),
  GeneratorInfo(
    name: 'service',
    description: 'Create a service inside a feature.',
    example: 'rekeens generate service auth auth',
  ),
  GeneratorInfo(
    name: 'provider',
    description:
        'Create a provider (riverpod) or cubit+state (bloc) inside a feature.',
    example: 'rekeens generate provider auth auth',
  ),
];
