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
    final localization = options['localization'] as bool? ?? false;

    await _writeMainDart(projectName, stateManagement: stateManagement);
    if (stateManagement == 'bloc') {
      await _writeAppCubit(projectName);
    }
    await _writeAppDart(
      projectName,
      title: projectName,
      useGoRouter: router == 'go_router',
      useMaterial3: theme == 'material3',
      useLocalization: localization,
    );
    await _writeRouterDart(projectName, useGoRouter: router == 'go_router');

    if (localization) {
      await _configureLocalization(projectName);
    }
  }

  Future<void> _writeMainDart(
    String projectName, {
    required String stateManagement,
  }) async {
    final mainFile = File(p.join(projectName, 'lib', 'main.dart'));
    final useRiverpod = stateManagement == 'riverpod';
    final useBloc = stateManagement == 'bloc';
    final buffer = StringBuffer();

    buffer.writeln("import 'package:flutter/material.dart';");
    if (useRiverpod) {
      buffer.writeln(
        "import 'package:flutter_riverpod/flutter_riverpod.dart';",
      );
    } else if (useBloc) {
      buffer.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
      buffer.writeln("import 'app/app_cubit.dart';");
    }
    buffer.writeln("import 'app/app.dart';");
    buffer.writeln();
    buffer.writeln('void main() {');
    if (useRiverpod) {
      buffer.writeln('  runApp(const ProviderScope(child: App()));');
    } else if (useBloc) {
      buffer.writeln(
        '  runApp(BlocProvider<AppCubit>(create: (_) => AppCubit(), child: const App()));',
      );
    } else {
      buffer.writeln('  runApp(const App());');
    }
    buffer.writeln('}');

    await mainFile.writeAsString(buffer.toString());
  }

  Future<void> _writeAppCubit(String projectName) async {
    final cubitFile = File(p.join(projectName, 'lib', 'app', 'app_cubit.dart'));
    await cubitFile.writeAsString('''
import 'package:flutter_bloc/flutter_bloc.dart';

class AppState {
  const AppState();
}

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(const AppState());
}
''');
  }

  Future<void> _writeAppDart(
    String projectName, {
    required String title,
    required bool useGoRouter,
    required bool useMaterial3,
    required bool useLocalization,
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
    if (useLocalization) {
      buffer.writeln("import '../l10n/app_localizations.dart';");
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
    if (useLocalization) {
      buffer.writeln(
        '      localizationsDelegates: AppLocalizations.localizationsDelegates,',
      );
      buffer.writeln(
        '      supportedLocales: AppLocalizations.supportedLocales,',
      );
    }
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

  Future<void> _configureLocalization(String projectName) async {
    final l10nDir = Directory(p.join(projectName, 'lib', 'l10n'));
    l10nDir.createSync(recursive: true);

    final l10nYaml = File(p.join(projectName, 'l10n.yaml'));
    await l10nYaml.writeAsString('''
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/l10n
''');

    final arbFile = File(p.join(l10nDir.path, 'app_en.arb'));
    await arbFile.writeAsString('''
{
  "appTitle": "{{project_name}}",
  "@appTitle": {
    "description": "Application title"
  }
}
''');
    final arbContent = await arbFile.readAsString();
    await arbFile.writeAsString(
      arbContent.replaceAll('{{project_name}}', projectName),
    );
  }

  Future<void> enableFlutterGenerate(String projectName) async {
    final pubspecFile = File(p.join(projectName, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return;

    final lines = await pubspecFile.readAsLines();

    var inFlutterSection = false;
    for (final line in lines) {
      if (line == 'flutter:') {
        inFlutterSection = true;
        continue;
      }
      if (inFlutterSection) {
        if (line.isNotEmpty &&
            !line.startsWith(' ') &&
            !line.startsWith('\t')) {
          inFlutterSection = false;
          continue;
        }
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('generate:') && trimmed.contains('true')) {
          return;
        }
      }
    }

    final output = <String>[];
    var inserted = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      output.add(line);

      if (!inserted && line == 'flutter:') {
        output.add('  generate: true');
        inserted = true;
      }
    }

    if (!inserted) {
      output.add('');
      output.add('flutter:');
      output.add('  generate: true');
    }

    await pubspecFile.writeAsString('${output.join('\n')}\n');
  }
}
