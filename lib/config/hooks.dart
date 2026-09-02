import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:rekeens_flutter_cli/utils/logger.dart';

/// A single hook command parsed from `rekeens.yaml`.
class HookConfig {
  const HookConfig({required this.run, this.when, this.description});

  /// Shell command to execute.
  final String run;

  /// Optional list of generator types that trigger this hook.
  /// `null` means "all generators".
  final List<String>? when;

  /// Optional human-readable description shown in logs.
  final String? description;

  bool appliesTo(String generatorType) {
    if (when == null || when!.isEmpty) return true;
    return when!.contains(generatorType);
  }
}

/// The set of hooks for a single lifecycle point (before/after generate).
class HookSet {
  const HookSet({
    this.beforeGenerate = const [],
    this.afterGenerate = const [],
  });

  final List<HookConfig> beforeGenerate;
  final List<HookConfig> afterGenerate;

  bool get isEmpty => beforeGenerate.isEmpty && afterGenerate.isEmpty;
}

/// Context passed to [HookRunner] — the generator invocation details.
class HookContext {
  const HookContext({
    required this.generatorType,
    required this.featureName,
    this.entityName,
    this.dryRun = false,
  });

  final String generatorType;
  final String featureName;
  final String? entityName;
  final bool dryRun;
}

/// Executes shell commands defined as hooks in `rekeens.yaml`.
class HookRunner {
  HookRunner({Logger? log, String? workingDirectory})
    : _log = log ?? logger,
      _workingDirectory = workingDirectory ?? Directory.current.path;

  final Logger _log;
  final String _workingDirectory;

  /// Runs [hooks] that apply to [context.generatorType].
  ///
  /// In `--dry-run` mode, logs the command that would be executed without
  /// actually running it.
  Future<void> runHooks(List<HookConfig> hooks, HookContext context) async {
    for (final hook in hooks) {
      if (!hook.appliesTo(context.generatorType)) continue;

      final label = hook.description != null
          ? '${hook.description} (${hook.run})'
          : hook.run;

      if (context.dryRun) {
        _log.warn('DRY RUN: would run hook "$label"');
        continue;
      }

      _log.info('Running hook: $label');

      final env = Map<String, String>.from(Platform.environment)
        ..['REKEENS_GENERATOR_TYPE'] = context.generatorType
        ..['REKEENS_FEATURE_NAME'] = context.featureName;
      if (context.entityName != null) {
        env['REKEENS_ENTITY_NAME'] = context.entityName!;
      }

      final result = await Process.run(
        _shellExecutable(),
        [..._shellFlags(), hook.run],
        workingDirectory: _workingDirectory,
        environment: env,
      );

      if (result.exitCode != 0) {
        final stderr = result.stderr.toString().trim();
        final stdout = result.stdout.toString().trim();
        _log.err('Hook failed (exit ${result.exitCode}): $label');
        if (stdout.isNotEmpty) _log.info(stdout);
        if (stderr.isNotEmpty) _log.err(stderr);
        throw Exception(
          'Hook "$label" failed with exit code ${result.exitCode}.',
        );
      }

      final stdout = result.stdout.toString().trim();
      if (stdout.isNotEmpty) _log.info(stdout);
    }
  }

  String _shellExecutable() {
    if (Platform.isWindows) return 'cmd';
    return 'sh';
  }

  List<String> _shellFlags() {
    if (Platform.isWindows) return ['/c'];
    return ['-c'];
  }
}
