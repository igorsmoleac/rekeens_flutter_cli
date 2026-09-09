/// Runnable example for `rekeens_flutter_cli`.
///
/// Builds a minimal "Flutter project" skeleton inside a temporary
/// directory, then drives every generator through the same public API the
/// CLI uses. Run it from the package root:
///
/// ```sh
/// dart run example/main.dart
/// ```
///
/// The equivalent shell commands are shown next to each call:
///
/// ```sh
/// rekeens g feature auth
/// rekeens g model auth user id:string name:string email:string? age:int \
///   createdAt:datetime role:enum Role metadata:Map<String, dynamic>
/// rekeens g entity auth user
/// rekeens g usecase auth login
/// rekeens g repository auth user
/// rekeens g datasource auth user_api --base-url=https://api.demo.dev
/// rekeens g service auth auth_api
/// rekeens g provider auth session
/// rekeens g screen auth login
/// ```
///
/// The generated files stay on disk after the run so you can inspect them;
/// the temp directory path is printed at the end.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/datasource_generator.dart';
import 'package:rekeens_flutter_cli/generators/entity_generator.dart';
import 'package:rekeens_flutter_cli/generators/feature_generator.dart';
import 'package:rekeens_flutter_cli/generators/model_generator.dart';
import 'package:rekeens_flutter_cli/generators/provider_generator.dart';
import 'package:rekeens_flutter_cli/generators/repository_generator.dart';
import 'package:rekeens_flutter_cli/generators/screen_generator.dart';
import 'package:rekeens_flutter_cli/generators/service_generator.dart';
import 'package:rekeens_flutter_cli/generators/usecase_generator.dart';

Future<void> main() async {
  final project = Directory.systemTemp.createTempSync('rekeens_demo_');
  _writeProjectSkeleton(project);

  stdout.writeln('Demo project: ${project.path}\n');

  // rekeens g feature auth
  await FeatureGenerator(workingDirectory: project.path).generate('auth');

  // rekeens g model auth user id:string name:string email:string? age:int \
  //   createdAt:datetime role:enum Role metadata:Map<String, dynamic>
  await ModelGenerator(workingDirectory: project.path).generate(
    'auth',
    'user',
    fields: [
      'id:string',
      'name:string',
      'email:string?',
      'age:int',
      'createdAt:datetime',
      'role:enum Role',
      'metadata:Map<String, dynamic>',
    ],
  );

  // rekeens g entity auth user
  await EntityGenerator(
    workingDirectory: project.path,
  ).generate('auth', 'user');

  // rekeens g usecase auth login
  await UseCaseGenerator(
    workingDirectory: project.path,
  ).generate('auth', 'login');

  // rekeens g repository auth user
  await RepositoryGenerator(
    workingDirectory: project.path,
  ).generate('auth', 'user');

  // rekeens g datasource auth user_api --base-url=https://api.demo.dev
  await DatasourceGenerator(
    workingDirectory: project.path,
  ).generate('auth', 'user_api', baseUrl: 'https://api.demo.dev');

  // rekeens g service auth auth_api
  await ServiceGenerator(
    workingDirectory: project.path,
  ).generate('auth', 'auth_api');

  // rekeens g provider auth session
  await ProviderGenerator(
    workingDirectory: project.path,
  ).generate('auth', 'session', stateManagement: 'riverpod');

  // rekeens g screen auth login
  await ScreenGenerator(
    workingDirectory: project.path,
  ).generate('auth', 'login');

  stdout.writeln('\nGenerated project tree:');
  _printTree(project.path);

  final modelPath = p.join(
    project.path,
    'lib',
    'features',
    'auth',
    'data',
    'models',
    'user_model.dart',
  );
  stdout
    ..writeln('\n--- lib/features/auth/data/models/user_model.dart ---')
    ..writeln(File(modelPath).readAsStringSync());
}

/// Creates the minimum structure the generators expect in a target project:
/// a `pubspec.yaml` with a package name, a go_router-based
/// `lib/app/router.dart`, and a `home` feature page it references.
void _writeProjectSkeleton(Directory project) {
  Directory(
    p.join(project.path, 'lib', 'features'),
  ).createSync(recursive: true);
  File(p.join(project.path, 'pubspec.yaml')).writeAsStringSync('''
name: demo_app
description: Demo project scaffolded by the rekeens_flutter_cli example.
environment:
  sdk: ^3.12.0
dependencies:
  flutter_riverpod: ^3.0.3
  go_router: ^16.2.1
''');
  Directory(p.join(project.path, 'lib', 'app')).createSync(recursive: true);
  File(p.join(project.path, 'lib', 'app', 'router.dart')).writeAsStringSync('''
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
''');
}

void _printTree(String rootPath) {
  stdout.writeln('${p.basename(rootPath)}/');
  _walk(Directory(rootPath), '');
}

void _walk(Directory dir, String prefix) {
  final entities = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
  for (var i = 0; i < entities.length; i++) {
    final entity = entities[i];
    final isLast = i == entities.length - 1;
    final branch = isLast ? '└── ' : '├── ';
    final name = p.basename(entity.path);
    stdout.writeln('$prefix$branch$name');
    if (entity is Directory) {
      _walk(entity, '$prefix${isLast ? '    ' : '│   '}');
    }
  }
}
