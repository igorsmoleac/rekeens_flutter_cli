import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:rekeens_flutter_cli/config/config_loader.dart';
import 'package:rekeens_flutter_cli/config/presets.dart';
import 'package:rekeens_flutter_cli/services/prompter_service.dart';

class OptionsResolver {
  OptionsResolver({
    PrompterService? prompter,
    this._workingDirectory,
    this._homeDirectory,
  }) : _prompter = prompter ?? PrompterService();

  final PrompterService _prompter;
  final String? _workingDirectory;
  final String? _homeDirectory;

  Map<String, dynamic> resolve(ArgResults args, {required String usage}) {
    final presetName = args['preset'] as String?;
    if (presetName != null) {
      final preset = presets[presetName];
      if (preset == null) {
        throw UsageException(
          'Unknown preset "$presetName". Available: ${presets.keys.join(', ')}',
          usage,
        );
      }
      return _mergePresetWithFlags(preset, args);
    }

    final configOptions = ConfigLoader.load(
      workingDirectory: _workingDirectory,
      homeDirectory: _homeDirectory,
    );
    final hasFlags = _hasAnyCreateFlag(args);

    if (hasFlags) {
      final flagOptions = _collectOptionsFromFlags(args);
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

  bool _hasAnyCreateFlag(ArgResults args) {
    return args.wasParsed('platforms') ||
        args.wasParsed('architecture') ||
        args.wasParsed('state-management') ||
        args.wasParsed('router') ||
        args.wasParsed('networking') ||
        args.wasParsed('localization') ||
        args.wasParsed('theme') ||
        args.wasParsed('codegen');
  }

  Map<String, dynamic> _collectOptionsFromFlags(ArgResults args) {
    return _applyFlags(<String, dynamic>{}, args);
  }

  Map<String, dynamic> _mergePresetWithFlags(Preset preset, ArgResults args) {
    return _applyFlags(preset.toOptions(), args);
  }

  Map<String, dynamic> _applyFlags(
    Map<String, dynamic> options,
    ArgResults args,
  ) {
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
}
