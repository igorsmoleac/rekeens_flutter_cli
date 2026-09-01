import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/utils/logger.dart';

/// Adds routes to an existing `lib/app/router.dart` file.
///
/// Supports both go_router (GoRoute entries) and the simple AppRouter
/// (static const String route names) variants. Insertions are idempotent —
/// if a route path already exists, the file is left untouched.
class RouterUpdater {
  RouterUpdater({this.workingDirectory});

  final String? workingDirectory;

  String get _projectDir => workingDirectory ?? Directory.current.path;
  String get _routerPath => p.join(_projectDir, 'lib', 'app', 'router.dart');

  /// Adds a route for [featureName] (or a screen [screenName] within it).
  ///
  /// - [className] is the widget class to instantiate (e.g. `AuthPage`).
  /// - [fileName] is the Dart file name relative to the feature's `pages` dir.
  ///
  /// Skips silently if `router.dart` does not exist. Skips if the route path
  /// is already present (idempotent). Respects [dryRun].
  Future<void> addRoute({
    required String featureName,
    String? screenName,
    required String className,
    required String fileName,
    bool dryRun = false,
  }) async {
    final routerFile = File(_routerPath);
    if (!routerFile.existsSync()) {
      logger.warn(
        'router.dart not found at $_routerPath. Skipping route addition.',
      );
      return;
    }

    final content = routerFile.readAsStringSync();
    final routePath = screenName != null
        ? '/$featureName/$screenName'
        : '/$featureName';
    final isGoRouter = content.contains('GoRouter');

    if (_routeExists(content, routePath, isGoRouter)) {
      logger.info(
        'Route "$routePath" already exists in router.dart. Skipping.',
      );
      return;
    }

    if (dryRun) {
      logger.warn('DRY RUN: would add route "$routePath" to $_routerPath');
      return;
    }

    final importPath = '../features/$featureName/presentation/pages/$fileName';

    final updated = isGoRouter
        ? _addGoRoute(content, routePath, className, importPath)
        : _addRouteConstant(
            content,
            _toCamelCase(
              screenName != null ? '${featureName}_$screenName' : featureName,
            ),
            routePath,
          );

    routerFile.writeAsStringSync(updated);
    logger.success('Route "$routePath" added to router.dart.');
  }

  bool _routeExists(String content, String routePath, bool isGoRouter) {
    if (isGoRouter) {
      return content.contains("path: '$routePath'");
    }
    return content.contains("'$routePath'");
  }

  String _toCamelCase(String snakeCase) {
    final parts = snakeCase.split('_');
    return parts.first +
        parts.skip(1).map((part) {
          if (part.isEmpty) return '';
          return part[0].toUpperCase() + part.substring(1);
        }).join();
  }

  String _addGoRoute(
    String content,
    String path,
    String className,
    String importPath,
  ) {
    // Insert import after the last existing import line.
    final importLine = "import '$importPath';";
    final importRegex = RegExp(r'^import .+;$', multiLine: true);
    final imports = importRegex.allMatches(content);
    final lastImport = imports.isEmpty ? null : imports.last;

    String withImport;
    if (lastImport != null) {
      withImport =
          '${content.substring(0, lastImport.end)}\n$importLine${content.substring(lastImport.end)}';
    } else {
      withImport = '$importLine\n$content';
    }

    // Insert GoRoute before the closing `  ],\n);` of the GoRouter.
    final goRoute =
        '''
    GoRoute(
      path: '$path',
      builder: (context, state) => const $className(),
    ),''';

    final closingRegex = RegExp(r'  \],\n\);');
    final match = closingRegex.firstMatch(withImport);

    if (match != null) {
      return '${withImport.substring(0, match.start)}$goRoute\n${withImport.substring(match.start)}';
    }

    return withImport;
  }

  String _addRouteConstant(String content, String name, String path) {
    final constLine = "  static const String $name = '$path';";
    final closingRegex = RegExp(r'^\}', multiLine: true);
    final match = closingRegex.firstMatch(content);

    if (match != null) {
      return '${content.substring(0, match.start)}$constLine\n${content.substring(match.start)}';
    }

    return content;
  }
}
