import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/config/hooks.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late Logger logger;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('hook_runner_test_');
    logger = Logger(level: Level.verbose);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  HookRunner runnerWithCapture() {
    return HookRunner(log: logger, workingDirectory: tempDir.path);
  }

  group('HookConfig.appliesTo', () {
    test('returns true when when is null (applies to all)', () {
      const hook = HookConfig(run: 'echo hi');
      expect(hook.appliesTo('feature'), isTrue);
      expect(hook.appliesTo('model'), isTrue);
    });

    test('returns true when when contains the type', () {
      const hook = HookConfig(run: 'echo hi', when: ['model', 'entity']);
      expect(hook.appliesTo('model'), isTrue);
      expect(hook.appliesTo('entity'), isTrue);
    });

    test('returns false when when does not contain the type', () {
      const hook = HookConfig(run: 'echo hi', when: ['model']);
      expect(hook.appliesTo('feature'), isFalse);
    });

    test('returns true for all when when is empty', () {
      const hook = HookConfig(run: 'echo hi', when: []);
      expect(hook.appliesTo('feature'), isTrue);
    });
  });

  group('HookSet', () {
    test('isEmpty is true for default', () {
      const set = HookSet();
      expect(set.isEmpty, isTrue);
    });

    test('isEmpty is false when beforeGenerate is non-empty', () {
      const set = HookSet(beforeGenerate: [HookConfig(run: 'echo')]);
      expect(set.isEmpty, isFalse);
    });
  });

  group('HookRunner.runHooks', () {
    test('runs a simple echo command successfully', () async {
      final runner = runnerWithCapture();
      const context = HookContext(
        generatorType: 'feature',
        featureName: 'auth',
      );

      await runner.runHooks([
        const HookConfig(run: 'echo hello_world'),
      ], context);
      // No exception thrown = success.
    });

    test('writes a marker file via hook', () async {
      final runner = runnerWithCapture();
      const context = HookContext(
        generatorType: 'model',
        featureName: 'auth',
        entityName: 'user',
      );

      final markerPath = p.join(tempDir.path, 'hook_marker.txt');
      final cmd = Platform.isWindows
          ? 'echo done> $markerPath'
          : 'echo done > "$markerPath"';
      await runner.runHooks([HookConfig(run: cmd)], context);

      expect(File(markerPath).existsSync(), isTrue);
    });

    test('passes REKEENS_GENERATOR_TYPE env var', () async {
      final runner = runnerWithCapture();
      final envFile = p.join(tempDir.path, 'env.txt');

      const context = HookContext(
        generatorType: 'entity',
        featureName: 'auth',
        entityName: 'user',
      );

      final cmd = Platform.isWindows
          ? 'set REKEENS_GENERATOR_TYPE> $envFile'
          : 'echo \$REKEENS_GENERATOR_TYPE > "$envFile"';
      await runner.runHooks([HookConfig(run: cmd)], context);

      final content = File(envFile).readAsStringSync();
      expect(content.contains('entity'), isTrue);
    });

    test('passes REKEENS_FEATURE_NAME env var', () async {
      final runner = runnerWithCapture();
      final envFile = p.join(tempDir.path, 'env_feature.txt');

      const context = HookContext(
        generatorType: 'feature',
        featureName: 'myfeature',
      );

      final cmd = Platform.isWindows
          ? 'set REKEENS_FEATURE_NAME> $envFile'
          : 'echo \$REKEENS_FEATURE_NAME > "$envFile"';
      await runner.runHooks([HookConfig(run: cmd)], context);

      final content = File(envFile).readAsStringSync();
      expect(content.contains('myfeature'), isTrue);
    });

    test('skips hooks not matching generator type', () async {
      final runner = runnerWithCapture();
      final markerPath = p.join(tempDir.path, 'should_not_exist.txt');

      const context = HookContext(
        generatorType: 'feature',
        featureName: 'auth',
      );

      final cmd = Platform.isWindows
          ? 'echo nope> $markerPath'
          : 'echo nope > "$markerPath"';
      await runner.runHooks([
        HookConfig(run: cmd, when: ['model']),
      ], context);

      expect(File(markerPath).existsSync(), isFalse);
    });

    test('throws on failing hook (non-zero exit)', () async {
      final runner = runnerWithCapture();
      const context = HookContext(
        generatorType: 'feature',
        featureName: 'auth',
      );

      final cmd = Platform.isWindows ? 'exit /b 1' : 'exit 1';
      await expectLater(
        runner.runHooks([HookConfig(run: cmd)], context),
        throwsA(isA<Exception>()),
      );
    });

    test('dry-run does not execute commands', () async {
      final runner = runnerWithCapture();
      final markerPath = p.join(tempDir.path, 'dry_run_marker.txt');

      const context = HookContext(
        generatorType: 'feature',
        featureName: 'auth',
        dryRun: true,
      );

      final cmd = Platform.isWindows
          ? 'echo nope> $markerPath'
          : 'echo nope > "$markerPath"';
      await runner.runHooks([HookConfig(run: cmd)], context);

      expect(File(markerPath).existsSync(), isFalse);
    });

    test('runs multiple hooks in order', () async {
      final runner = runnerWithCapture();
      final file1 = p.join(tempDir.path, 'hook1.txt');
      final file2 = p.join(tempDir.path, 'hook2.txt');

      const context = HookContext(
        generatorType: 'feature',
        featureName: 'auth',
      );

      final cmd1 = Platform.isWindows ? 'echo 1> $file1' : 'echo 1 > "$file1"';
      final cmd2 = Platform.isWindows ? 'echo 2> $file2' : 'echo 2 > "$file2"';
      await runner.runHooks([
        HookConfig(run: cmd1),
        HookConfig(run: cmd2),
      ], context);

      expect(File(file1).existsSync(), isTrue);
      expect(File(file2).existsSync(), isTrue);
    });
  });
}
