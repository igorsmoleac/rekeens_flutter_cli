import 'dart:io';

import 'package:path/path.dart' as p;

class ProjectFileWriter {
  Future<void> configureProjectFiles(
    String projectName,
    Map<String, dynamic> options,
  ) async {
    final stateManagement = options['state_management'] as String;
    final router = options['router'] as String;
    final theme = options['theme'] as String;

    await _writeMainDart(projectName, stateManagement: stateManagement);
    await _writeAppDart(
      projectName,
      title: projectName,
      useGoRouter: router == 'go_router',
      useMaterial3: theme == 'material3',
    );
    await _writeRouterDart(projectName, useGoRouter: router == 'go_router');
  }

  Future<void> _writeMainDart(
    String projectName, {
    required String stateManagement,
  }) async {
    final mainFile = File(p.join(projectName, 'lib', 'main.dart'));
    final useRiverpod = stateManagement == 'riverpod';
    final buffer = StringBuffer();

    buffer.writeln("import 'package:flutter/material.dart';");
    if (useRiverpod) {
      buffer.writeln(
        "import 'package:flutter_riverpod/flutter_riverpod.dart';",
      );
    }
    buffer.writeln("import 'app/app.dart';");
    buffer.writeln();
    buffer.writeln('void main() {');
    if (useRiverpod) {
      buffer.writeln('  runApp(const ProviderScope(child: App()));');
    } else {
      buffer.writeln('  runApp(const App());');
    }
    buffer.writeln('}');

    await mainFile.writeAsString(buffer.toString());
  }

  Future<void> _writeAppDart(
    String projectName, {
    required String title,
    required bool useGoRouter,
    required bool useMaterial3,
  }) async {
    final appFile = File(p.join(projectName, 'lib', 'app', 'app.dart'));
    final buffer = StringBuffer();

    buffer.writeln("import 'package:flutter/material.dart';");
    if (useGoRouter) {
      buffer.writeln("import 'router.dart';");
    } else {
      buffer.writeln(
        "import '../features/home/presentation/pages/home_page.dart';",
      );
    }
    buffer.writeln();
    buffer.writeln('class App extends StatelessWidget {');
    buffer.writeln('  const App({super.key});');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    return MaterialApp${useGoRouter ? '.router' : ''}(');
    buffer.writeln("      title: '$title',");
    buffer.writeln('      theme: ThemeData(');
    buffer.writeln('        useMaterial3: $useMaterial3,');
    if (useMaterial3) {
      buffer.writeln(
        '        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),',
      );
    } else {
      buffer.writeln('        primarySwatch: Colors.blue,');
    }
    buffer.writeln('      ),');
    if (useGoRouter) {
      buffer.writeln('      routerConfig: appRouter,');
    } else {
      buffer.writeln('      home: const HomePage(),');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');

    await appFile.writeAsString(buffer.toString());
  }

  Future<void> _writeRouterDart(
    String projectName, {
    required bool useGoRouter,
  }) async {
    final routerFile = File(p.join(projectName, 'lib', 'app', 'router.dart'));
    final buffer = StringBuffer();

    if (useGoRouter) {
      buffer.writeln("import 'package:go_router/go_router.dart';");
      buffer.writeln(
        "import '../features/home/presentation/pages/home_page.dart';",
      );
      buffer.writeln();
      buffer.writeln('final appRouter = GoRouter(');
      buffer.writeln('  routes: [');
      buffer.writeln('    GoRoute(');
      buffer.writeln("      path: '/',");
      buffer.writeln('      builder: (context, state) => const HomePage(),');
      buffer.writeln('    ),');
      buffer.writeln('  ],');
      buffer.writeln(');');
    } else {
      buffer.writeln('class AppRouter {');
      buffer.writeln("  static const String home = '/';");
      buffer.writeln('}');
    }

    await routerFile.writeAsString(buffer.toString());
  }
}
