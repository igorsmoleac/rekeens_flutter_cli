import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/services/router_updater.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late RouterUpdater updater;

  const goRouterTemplate = """
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

  const simpleRouterTemplate = """
class AppRouter {
  static const String home = '/';
}
""";

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('router_updater_test_');
    Directory(p.join(tempDir.path, 'lib', 'app')).createSync(recursive: true);
    updater = RouterUpdater(workingDirectory: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  File routerFile() => File(p.join(tempDir.path, 'lib', 'app', 'router.dart'));

  group('RouterUpdater — go_router', () {
    setUp(() {
      routerFile().writeAsStringSync(goRouterTemplate);
    });

    test('adds a GoRoute for a feature', () async {
      await updater.addRoute(
        featureName: 'auth',
        className: 'AuthPage',
        fileName: 'auth_page.dart',
      );

      final content = routerFile().readAsStringSync();
      expect(content.contains("path: '/auth'"), isTrue);
      expect(content.contains('const AuthPage()'), isTrue);
      expect(
        content.contains(
          "import '../features/auth/presentation/pages/auth_page.dart';",
        ),
        isTrue,
      );
    });

    test('adds a GoRoute for a screen with nested path', () async {
      await updater.addRoute(
        featureName: 'auth',
        screenName: 'login',
        className: 'LoginScreen',
        fileName: 'login_screen.dart',
      );

      final content = routerFile().readAsStringSync();
      expect(content.contains("path: '/auth/login'"), isTrue);
      expect(content.contains('const LoginScreen()'), isTrue);
      expect(
        content.contains(
          "import '../features/auth/presentation/pages/login_screen.dart';",
        ),
        isTrue,
      );
    });

    test('is idempotent — skips if route path already exists', () async {
      await updater.addRoute(
        featureName: 'auth',
        className: 'AuthPage',
        fileName: 'auth_page.dart',
      );

      final contentAfterFirst = routerFile().readAsStringSync();

      await updater.addRoute(
        featureName: 'auth',
        className: 'AuthPage',
        fileName: 'auth_page.dart',
      );

      final contentAfterSecond = routerFile().readAsStringSync();
      expect(contentAfterSecond, contentAfterFirst);
    });

    test('preserves existing routes', () async {
      await updater.addRoute(
        featureName: 'auth',
        className: 'AuthPage',
        fileName: 'auth_page.dart',
      );

      final content = routerFile().readAsStringSync();
      expect(content.contains("path: '/'"), isTrue);
      expect(content.contains('const HomePage()'), isTrue);
    });

    test('dry-run does not modify the file', () async {
      final original = routerFile().readAsStringSync();

      await updater.addRoute(
        featureName: 'auth',
        className: 'AuthPage',
        fileName: 'auth_page.dart',
        dryRun: true,
      );

      expect(routerFile().readAsStringSync(), original);
    });
  });

  group('RouterUpdater — simple AppRouter', () {
    setUp(() {
      routerFile().writeAsStringSync(simpleRouterTemplate);
    });

    test('adds a route constant for a feature', () async {
      await updater.addRoute(
        featureName: 'auth',
        className: 'AuthPage',
        fileName: 'auth_page.dart',
      );

      final content = routerFile().readAsStringSync();
      expect(content.contains("static const String auth = '/auth';"), isTrue);
    });

    test('adds a route constant for a screen with camelCase name', () async {
      await updater.addRoute(
        featureName: 'auth',
        screenName: 'login',
        className: 'LoginScreen',
        fileName: 'login_screen.dart',
      );

      final content = routerFile().readAsStringSync();
      expect(
        content.contains("static const String authLogin = '/auth/login';"),
        isTrue,
      );
    });

    test('is idempotent — skips if route path already exists', () async {
      await updater.addRoute(
        featureName: 'auth',
        className: 'AuthPage',
        fileName: 'auth_page.dart',
      );

      final contentAfterFirst = routerFile().readAsStringSync();

      await updater.addRoute(
        featureName: 'auth',
        className: 'AuthPage',
        fileName: 'auth_page.dart',
      );

      expect(routerFile().readAsStringSync(), contentAfterFirst);
    });

    test('preserves existing route constants', () async {
      await updater.addRoute(
        featureName: 'auth',
        className: 'AuthPage',
        fileName: 'auth_page.dart',
      );

      final content = routerFile().readAsStringSync();
      expect(content.contains("static const String home = '/'"), isTrue);
    });
  });

  group('RouterUpdater — edge cases', () {
    test('skips silently when router.dart does not exist', () async {
      // No router.dart created in setUp for this group.
      await updater.addRoute(
        featureName: 'auth',
        className: 'AuthPage',
        fileName: 'auth_page.dart',
      );

      expect(routerFile().existsSync(), isFalse);
    });

    test(
      'handles multi-word feature names in camelCase for simple router',
      () async {
        routerFile().writeAsStringSync(simpleRouterTemplate);

        await updater.addRoute(
          featureName: 'user_profile',
          screenName: 'edit',
          className: 'EditScreen',
          fileName: 'edit_screen.dart',
        );

        final content = routerFile().readAsStringSync();
        expect(
          content.contains(
            "static const String userProfileEdit = '/user_profile/edit';",
          ),
          isTrue,
        );
      },
    );
  });
}
