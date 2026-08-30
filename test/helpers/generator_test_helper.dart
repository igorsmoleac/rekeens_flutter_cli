import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/feature_generator.dart';
import 'package:test/test.dart';

class GeneratorTestHelper {
  late final String projectRoot;
  late Directory tempProject;

  void register() {
    setUpAll(() {
      projectRoot = Directory.current.path;
    });

    setUp(() {
      tempProject = Directory.systemTemp.createTempSync('gen_test_');
      Directory(p.join(tempProject.path, 'lib', 'features'))
          .createSync(recursive: true);
      File(p.join(tempProject.path, 'pubspec.yaml'))
          .writeAsStringSync('name: test\n');
    });

    tearDown(() {
      if (tempProject.existsSync()) {
        tempProject.deleteSync(recursive: true);
      }
    });
  }

  FeatureGenerator featureGenerator() => FeatureGenerator(
    workingDirectory: tempProject.path,
    templatesRootOverride: projectRoot,
  );

  Future<void> withAuthFeature(Future<void> Function() body) async {
    final featureGen = FeatureGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );
    await featureGen.generate('auth');
    await body();
  }
}
