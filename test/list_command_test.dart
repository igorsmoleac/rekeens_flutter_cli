import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:rekeens_flutter_cli/commands/list_command.dart';
import 'package:test/test.dart';

void main() {
  group('ListCommand', () {
    late List<int> stdoutBytes;
    late List<int> stderrBytes;
    late ListCommand command;

    setUp(() {
      stdoutBytes = <int>[];
      stderrBytes = <int>[];
      command = ListCommand(log: Logger(level: Level.verbose));
    });

    Future<String> runAndCapture(Future<void> Function() body) async {
      late String out;
      late String err;
      await IOOverrides.runZoned(
        () async {
          await body();
          out = utf8.decode(stdoutBytes);
          err = utf8.decode(stderrBytes);
        },
        stdout: () => _MemoryStdout(stdoutBytes),
        stderr: () => _MemoryStdout(stderrBytes),
      );
      return '$out\n$err';
    }

    test('name is "list"', () {
      expect(command.name, 'list');
    });

    test('description is non-empty', () {
      expect(command.description, isNotEmpty);
    });

    test('lists all presets', () async {
      final out = await runAndCapture(() => command.run());
      expect(out, contains('Presets'));
      expect(out, contains('minimal'));
      expect(out, contains('mobile'));
      expect(out, contains('full'));
    });

    test('lists all generators', () async {
      final out = await runAndCapture(() => command.run());
      expect(out, contains('Generators'));
      expect(out, contains('feature'));
      expect(out, contains('screen'));
      expect(out, contains('model'));
      expect(out, contains('repository'));
      expect(out, contains('service'));
      expect(out, contains('provider'));
      expect(out, contains('entity'));
      expect(out, contains('usecase'));
    });

    test('includes usage examples for generators', () async {
      final out = await runAndCapture(() => command.run());
      expect(out, contains('rekeens generate feature auth'));
      expect(out, contains('rekeens generate screen auth login'));
      expect(out, contains('rekeens generate model auth user'));
      expect(out, contains('rekeens generate repository auth user'));
      expect(out, contains('rekeens generate service auth auth'));
      expect(out, contains('rekeens generate provider auth auth'));
      expect(out, contains('rekeens generate entity auth user'));
      expect(out, contains('rekeens generate usecase auth login'));
    });

    test('includes preset details', () async {
      final out = await runAndCapture(() => command.run());
      expect(out, contains('platforms'));
      expect(out, contains('state'));
      expect(out, contains('router'));
      expect(out, contains('networking'));
      expect(out, contains('storage'));
      expect(out, contains('theme'));
    });

    test('generators list matches the generate command types', () {
      final names = generators.map((g) => g.name).toSet();
      expect(names, {
        'feature',
        'screen',
        'model',
        'repository',
        'service',
        'provider',
        'entity',
        'usecase',
      });
    });
  });
}

class _MemoryStdout implements Stdout {
  _MemoryStdout(this._bytes);

  final List<int> _bytes;

  @override
  void write(object) {
    if (object is List<int>) {
      _bytes.addAll(object);
    } else {
      _bytes.addAll(utf8.encode('$object'));
    }
  }

  @override
  void writeln([object = '']) {
    write(object);
    _bytes.add(10);
  }

  @override
  bool get supportsAnsiEscapes => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
