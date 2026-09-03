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
      Directory(
        p.join(tempProject.path, 'lib', 'features'),
      ).createSync(recursive: true);
      Directory(
        p.join(tempProject.path, 'lib', 'app'),
      ).createSync(recursive: true);
      File(
        p.join(tempProject.path, 'pubspec.yaml'),
      ).writeAsStringSync('name: test\n');
      // Create a go_router-style router.dart so generators can add routes.
      File(
        p.join(tempProject.path, 'lib', 'app', 'router.dart'),
      ).writeAsStringSync(_goRouterTemplate);
    });

    tearDown(() {
      if (tempProject.existsSync()) {
        tempProject.deleteSync(recursive: true);
      }
    });
  }

  static const _goRouterTemplate = """
import 'package:go_router/go_router.dart';
import '../features/home/presentation/pages/home_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
  ],
);
""";

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
