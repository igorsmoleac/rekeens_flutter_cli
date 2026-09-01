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

  static const _allowedArchitecture = ['feature-first'];
  static const _allowedStateManagement = ['riverpod', 'bloc', 'none'];
  static const _allowedRouter = ['go_router', 'none'];
  static const _allowedNetworking = ['dio', 'http', 'none'];
  static const _allowedStorage = [
    'shared_preferences',
    'secure_storage',
    'none',
  ];
  static const _allowedTheme = ['material3', 'material2'];

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
      return _mergePresetWithFlags(preset, args, usage: usage);
    }

    final configOptions = ConfigLoader.load(
      workingDirectory: _workingDirectory,
      homeDirectory: _homeDirectory,
    );
    if (configOptions != null) {
      _validateConfigOptions(configOptions, usage: usage);
    }
    final hasFlags = _hasAnyCreateFlag(args);

    if (hasFlags) {
      final flagOptions = _collectOptionsFromFlags(args, usage: usage);
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
        args.wasParsed('storage') ||
        args.wasParsed('localization') ||
        args.wasParsed('theme') ||
        args.wasParsed('codegen');
  }

  Map<String, dynamic> _collectOptionsFromFlags(
    ArgResults args, {
    required String usage,
  }) {
    return _applyFlags(<String, dynamic>{}, args, usage: usage);
  }

  Map<String, dynamic> _mergePresetWithFlags(
    Preset preset,
    ArgResults args, {
    required String usage,
  }) {
    return _applyFlags(preset.toOptions(), args, usage: usage);
  }

  Map<String, dynamic> _applyFlags(
    Map<String, dynamic> options,
    ArgResults args, {
    required String usage,
  }) {
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
      final value = args['architecture'] as String?;
      _validateEnumValue(
        'architecture',
        value,
        _allowedArchitecture,
        usage: usage,
      );
      options['architecture'] = value;
    }
    if (args.wasParsed('state-management')) {
      final value = args['state-management'] as String?;
      _validateEnumValue(
        'state-management',
        value,
        _allowedStateManagement,
        usage: usage,
      );
      options['state_management'] = value;
    }
    if (args.wasParsed('router')) {
      final value = args['router'] as String?;
      _validateEnumValue('router', value, _allowedRouter, usage: usage);
      options['router'] = value;
    }
    if (args.wasParsed('networking')) {
      final value = args['networking'] as String?;
      _validateEnumValue('networking', value, _allowedNetworking, usage: usage);
      options['networking'] = value;
    }
    if (args.wasParsed('storage')) {
      final value = args['storage'] as String?;
      _validateEnumValue('storage', value, _allowedStorage, usage: usage);
      options['storage'] = value;
    }
    if (args.wasParsed('localization')) {
      options['localization'] = args['localization'];
    }
    if (args.wasParsed('theme')) {
      final value = args['theme'] as String?;
      _validateEnumValue('theme', value, _allowedTheme, usage: usage);
      options['theme'] = value;
    }
    if (args.wasParsed('codegen')) {
      options['codegen'] = args['codegen'];
    }

    return options;
  }

  void _validateEnumValue(
    String label,
    Object? value,
    List<String> allowed, {
    required String usage,
  }) {
    if (value == null) return;
    if (!allowed.contains(value)) {
      throw UsageException(
        'Invalid value "$value" for $label. Available: ${allowed.join(', ')}',
        usage,
      );
    }
  }

  void _validateConfigOptions(
    Map<String, dynamic> options, {
    required String usage,
  }) {
    _validateEnumValue(
      'architecture',
      options['architecture'],
      _allowedArchitecture,
      usage: usage,
    );
    _validateEnumValue(
      'state_management',
      options['state_management'],
      _allowedStateManagement,
      usage: usage,
    );
    _validateEnumValue(
      'router',
      options['router'],
      _allowedRouter,
      usage: usage,
    );
    _validateEnumValue(
      'networking',
      options['networking'],
      _allowedNetworking,
      usage: usage,
    );
    _validateEnumValue(
      'storage',
      options['storage'],
      _allowedStorage,
      usage: usage,
    );
    _validateEnumValue('theme', options['theme'], _allowedTheme, usage: usage);
  }

  Map<String, dynamic> _fillDefaults(Map<String, dynamic> partial) {
    return {
      'platforms':
          partial['platforms'] ?? ['android', 'ios', 'windows', 'linux'],
      'architecture': partial['architecture'] ?? 'feature-first',
      'state_management': partial['state_management'] ?? 'riverpod',
      'router': partial['router'] ?? 'go_router',
      'networking': partial['networking'] ?? 'dio',
      'storage': partial['storage'] ?? 'shared_preferences',
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

    final storage = _prompter.askChoice('Local storage', [
      'shared_preferences',
      'secure_storage',
      'none',
    ], defaultValue: 'shared_preferences');

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
      'storage': storage,
      'localization': localization,
      'theme': theme,
      'codegen': codegen,
    };
  }
}
