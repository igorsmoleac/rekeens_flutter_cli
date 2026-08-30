import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/project_file_writer.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempProject;
  late ProjectFileWriter writer;

  setUp(() {
    tempProject = Directory.systemTemp.createTempSync('pfw_test_');
    Directory(p.join(tempProject.path, 'lib', 'app'))
        .createSync(recursive: true);
    writer = ProjectFileWriter();
  });

  tearDown(() {
    if (tempProject.existsSync()) {
      tempProject.deleteSync(recursive: true);
    }
  });

  group('ProjectFileWriter main.dart', () {
    test('wraps app in BlocProvider when state_management=bloc', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'bloc',
        'router': 'none',
        'theme': 'material3',
        'localization': false,
      });

      final mainFile = File(p.join(tempProject.path, 'lib', 'main.dart'));
      expect(mainFile.existsSync(), isTrue);
      final content = mainFile.readAsStringSync();
      expect(
        content.contains("import 'package:flutter_bloc/flutter_bloc.dart'"),
        isTrue,
      );
      expect(content.contains("import 'app/app_cubit.dart'"), isTrue);
      expect(content.contains('BlocProvider<AppCubit>'), isTrue);
      expect(content.contains('AppCubit()'), isTrue);
    });

    test(
      'creates app_cubit.dart with AppCubit and AppState when bloc',
      () async {
        await writer.configureProjectFiles(tempProject.path, {
          'state_management': 'bloc',
          'router': 'none',
          'theme': 'material3',
          'localization': false,
        });

        final cubitFile = File(
          p.join(tempProject.path, 'lib', 'app', 'app_cubit.dart'),
        );
        expect(cubitFile.existsSync(), isTrue);
        final content = cubitFile.readAsStringSync();
        expect(content.contains('class AppCubit'), isTrue);
        expect(content.contains('class AppState'), isTrue);
        expect(content.contains('Cubit<AppState>'), isTrue);
      },
    );

    test('wraps app in ProviderScope when state_management=riverpod', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'riverpod',
        'router': 'none',
        'theme': 'material3',
        'localization': false,
      });

      final mainFile = File(p.join(tempProject.path, 'lib', 'main.dart'));
      expect(mainFile.existsSync(), isTrue);
      final content = mainFile.readAsStringSync();
      expect(
        content.contains(
          "import 'package:flutter_riverpod/flutter_riverpod.dart'",
        ),
        isTrue,
      );
      expect(content.contains('ProviderScope'), isTrue);
      expect(
        File(p.join(tempProject.path, 'lib', 'app', 'app_cubit.dart'))
            .existsSync(),
        isFalse,
      );
    });

    test('uses plain runApp when state_management=none', () async {
      await writer.configureProjectFiles(tempProject.path, {
        'state_management': 'none',
        'router': 'none',
        'theme': 'material3',
        'localization': false,
      });

      final mainFile = File(p.join(tempProject.path, 'lib', 'main.dart'));
      expect(mainFile.existsSync(), isTrue);
      final content = mainFile.readAsStringSync();
      expect(content.contains('runApp(const App())'), isTrue);
      expect(content.contains('ProviderScope'), isFalse);
      expect(content.contains('BlocProvider'), isFalse);
    });
  });
}
