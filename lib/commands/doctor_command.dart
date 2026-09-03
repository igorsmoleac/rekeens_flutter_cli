import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/utils/logger.dart';

typedef ProcessRunner =
    Future<ProcessResult> Function(
      String executable,
      List<String> args, {
      Map<String, String>? environment,
    });

class DoctorCommand extends Command<void> {
  DoctorCommand({
    ProcessRunner? processRunner,
    Map<String, String>? environment,
  }) : processRunner = processRunner ?? _defaultProcessRunner,
       environment = environment ?? Platform.environment;
  final ProcessRunner processRunner;
  final Map<String, String> environment;

  @override
  String get name => 'doctor';

  @override
  String get description => 'Check the development environment.';

  @override
  Future<void> run() async {
    logger.info('Rekeens CLI Doctor');
    logger.info('');

    var allGood = true;

    allGood = await _checkTool('Dart', ['--version']) && allGood;
    allGood = await _checkTool('Flutter', ['--version']) && allGood;
    allGood = await _checkTool('Git', ['--version']) && allGood;

    logger.info('');
    logger.info('Optional tools');
    logger.info('');

    final androidOk = await _checkAndroidSdk();
    final xcodeOk = await _checkXcode();
    final chromeOk = await _checkChrome();

    final optionalOk = androidOk && xcodeOk && chromeOk;

    logger.info('');
    if (allGood) {
      logger.success('Core environment is ready.');
    } else {
      logger.err('Some core tools are missing or not in PATH.');
      exitCode = 1;
    }

    if (optionalOk) {
      logger.success('All optional tools are available.');
    } else {
      logger.warn(
        'Some optional tools are missing (mobile/web development may be limited).',
      );
    }
  }

  Future<bool> _checkTool(String name, List<String> args) async {
    try {
      final result = await _run(name, args);
      if (result.exitCode != 0) {
        logger.err('$name: failed to run');
        return false;
      }
      final version = extractVersion(name, result.stdout.toString());
      logger.success(version.isEmpty ? name : version);
      return true;
    } on ProcessException {
      logger.err('$name: not found');
      return false;
    }
  }

  Future<bool> _checkAndroidSdk() async {
    final sdkRoot =
        environment['ANDROID_HOME'] ?? environment['ANDROID_SDK_ROOT'];
    if (sdkRoot == null || sdkRoot.isEmpty) {
      logger.err('Android SDK: ANDROID_HOME/ANDROID_SDK_ROOT not set');
      return false;
    }
    final dir = Directory(sdkRoot);
    if (!dir.existsSync()) {
      logger.err('Android SDK: $sdkRoot does not exist');
      return false;
    }
    final platformTools = Directory(p.join(sdkRoot, 'platform-tools'));
    final adb = platformTools.existsSync() ? ' (platform-tools present)' : '';
    logger.success('Android SDK: $sdkRoot$adb');
    return true;
  }

  Future<bool> _checkXcode() async {
    if (!Platform.isMacOS) {
      logger.info('Xcode: skipped (not macOS)');
      return true;
    }
    try {
      final result = await _run('xcodebuild', ['-version']);
      if (result.exitCode != 0) {
        logger.err('Xcode: failed to run');
        return false;
      }
      final version = extractVersion('Xcode', result.stdout.toString());
      logger.success('Xcode $version');
      return true;
    } on ProcessException {
      logger.err('Xcode: not found');
      return false;
    }
  }

  Future<bool> _checkChrome() async {
    final candidates = _chromeCandidates();
    for (final candidate in candidates) {
      final executable = candidate.executable;
      final args = candidate.args;
      try {
        final result = await _run(executable, args);
        if (result.exitCode == 0) {
          final version = extractVersion('Chrome', result.stdout.toString());
          if (version.isNotEmpty) {
            logger.success('Chrome $version');
            return true;
          }
        }
      } on ProcessException {
        continue;
      }
    }
    final path = _findChromeOnDisk();
    if (path != null) {
      logger.success('Chrome: found at $path');
      return true;
    }
    logger.err('Chrome: not found');
    return false;
  }

  List<_CommandCandidate> _chromeCandidates() {
    if (Platform.isWindows) {
      return const [
        _CommandCandidate('cmd', ['/c', 'chrome', '--version']),
      ];
    }
    if (Platform.isMacOS) {
      return const [
        _CommandCandidate(
          '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
          ['--version'],
        ),
        _CommandCandidate('google-chrome', ['--version']),
      ];
    }
    return const [
      _CommandCandidate('google-chrome', ['--version']),
      _CommandCandidate('chromium', ['--version']),
      _CommandCandidate('chrome', ['--version']),
    ];
  }

  String? _findChromeOnDisk() {
    if (Platform.isWindows) {
      final candidates = [
        p.join(
          environment['PROGRAMFILES'] ?? r'C:\Program Files',
          'Google',
          'Chrome',
          'Application',
          'chrome.exe',
        ),
        p.join(
          environment['PROGRAMFILES(X86)'] ?? r'C:\Program Files (x86)',
          'Google',
          'Chrome',
          'Application',
          'chrome.exe',
        ),
        p.join(
          environment['LOCALAPPDATA'] ?? '',
          'Google',
          'Chrome',
          'Application',
          'chrome.exe',
        ),
      ];
      for (final c in candidates) {
        if (c.isNotEmpty && File(c).existsSync()) return c;
      }
    } else if (Platform.isMacOS) {
      const path =
          '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
      if (File(path).existsSync()) return path;
    } else {
      const candidates = [
        '/usr/bin/google-chrome',
        '/usr/bin/chromium',
        '/usr/bin/chromium-browser',
        '/snap/bin/chromium',
      ];
      for (final c in candidates) {
        if (File(c).existsSync()) return c;
      }
    }
    return null;
  }

  Future<ProcessResult> _run(
    String executable,
    List<String> args, {
    Map<String, String>? env,
  }) async {
    if (Platform.isWindows &&
        !executable.contains(Platform.pathSeparator) &&
        !executable.contains('/')) {
      return processRunner('cmd', [
        '/c',
        executable,
        ...args,
      ], environment: env);
    }
    return processRunner(executable, args, environment: env);
  }

  @visibleForTesting
  String extractVersion(String tool, String output) {
    final lines = output.trim().split('\n');
    if (lines.isEmpty) return '';

    var line = lines.first.trim();

    line = line.replaceAll('•', '-');
    line = line.replaceAll(RegExp(r'[^\x00-\x7F]'), '');

    if (tool == 'Dart') {
      final match = RegExp(r'Dart SDK version: (\S+)').firstMatch(line);
      if (match != null) return 'Dart ${match.group(1)}';
    }

    if (tool == 'Flutter') {
      final match = RegExp(r'Flutter (\S+)').firstMatch(line);
      if (match != null) return 'Flutter ${match.group(1)}';
    }

    if (tool == 'Xcode') {
      final match = RegExp(r'Xcode (\S+)').firstMatch(line);
      if (match != null) return 'Xcode ${match.group(1)}';
    }

    if (tool == 'Chrome') {
      final match = RegExp(r'(\d+\.\d+\.\d+\.\d+)').firstMatch(line);
      if (match != null) return 'Chrome ${match.group(1)}';
    }

    return line;
  }
}

class _CommandCandidate {
  const _CommandCandidate(this.executable, this.args);
  final String executable;
  final List<String> args;
}

Future<ProcessResult> _defaultProcessRunner(
  String executable,
  List<String> args, {
  Map<String, String>? environment,
}) {
  return Process.run(executable, args, environment: environment);
}
