import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/feature_generator.dart';
import 'package:rekeens_flutter_cli/generators/model_generator.dart';
import 'package:rekeens_flutter_cli/generators/screen_generator.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempProject;
  late String projectRoot;

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

  test('FeatureGenerator creates feature structure', () async {
    final generator = FeatureGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );
    await generator.generate('auth');

    final featureDir = Directory(
      p.join(tempProject.path, 'lib', 'features', 'auth'),
    );
    expect(featureDir.existsSync(), isTrue);
    expect(Directory(p.join(featureDir.path, 'data')).existsSync(), isTrue);
    expect(Directory(p.join(featureDir.path, 'domain')).existsSync(), isTrue);
    expect(
      File(p.join(featureDir.path, 'presentation', 'pages', 'auth_page.dart'))
          .existsSync(),
      isTrue,
    );
  });

  test('ScreenGenerator creates screen file', () async {
    final featureGen = FeatureGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );
    await featureGen.generate('auth');

    final screenGen = ScreenGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );
    await screenGen.generate('auth', 'login');

    final screenFile = File(
      p.join(
        tempProject.path,
        'lib',
        'features',
        'auth',
        'presentation',
        'pages',
        'login_screen.dart',
      ),
    );
    expect(screenFile.existsSync(), isTrue);
    final content = screenFile.readAsStringSync();
    expect(content.contains('class LoginScreen'), isTrue);
  });

  test('ModelGenerator creates model file', () async {
    final featureGen = FeatureGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );
    await featureGen.generate('auth');

    final modelGen = ModelGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );
    await modelGen.generate('auth', 'user');

    final modelFile = File(
      p.join(
        tempProject.path,
        'lib',
        'features',
        'auth',
        'data',
        'models',
        'user_model.dart',
      ),
    );
    expect(modelFile.existsSync(), isTrue);
    final content = modelFile.readAsStringSync();
    expect(content.contains('class UserModel'), isTrue);
  });

  test('ModelGenerator generates fields from arguments', () async {
    final featureGen = FeatureGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );
    await featureGen.generate('auth');

    final modelGen = ModelGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );
    await modelGen.generate(
      'auth',
      'user',
      fields: ['name:string', 'age:int', 'price:double', 'active:bool'],
    );

    final modelFile = File(
      p.join(
        tempProject.path,
        'lib',
        'features',
        'auth',
        'data',
        'models',
        'user_model.dart',
      ),
    );
    expect(modelFile.existsSync(), isTrue);
    final content = modelFile.readAsStringSync();
    expect(content.contains('class UserModel'), isTrue);
    expect(content.contains('final String name;'), isTrue);
    expect(content.contains('final int age;'), isTrue);
    expect(content.contains('final double price;'), isTrue);
    expect(content.contains('final bool active;'), isTrue);
    expect(content.contains('required this.name,'), isTrue);
    expect(content.contains('required this.age,'), isTrue);
    expect(content.contains("name: json['name'] as String,"), isTrue);
    expect(content.contains("age: json['age'] as int,"), isTrue);
    expect(
      content.contains("price: (json['price'] as num).toDouble(),"),
      isTrue,
    );
    expect(content.contains("'name': name,"), isTrue);
    expect(content.contains("'age': age,"), isTrue);
  });

  test('ModelGenerator generates DateTime and List fields', () async {
    final featureGen = FeatureGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );
    await featureGen.generate('auth');

    final modelGen = ModelGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );
    await modelGen.generate(
      'auth',
      'user',
      fields: ['createdAt:DateTime', 'tags:List<String>'],
    );

    final modelFile = File(
      p.join(
        tempProject.path,
        'lib',
        'features',
        'auth',
        'data',
        'models',
        'user_model.dart',
      ),
    );
    final content = modelFile.readAsStringSync();
    expect(content.contains('final DateTime createdAt;'), isTrue);
    expect(content.contains('final List<String> tags;'), isTrue);
    expect(
      content.contains(
        "createdAt: DateTime.parse(json['createdAt'] as String),",
      ),
      isTrue,
    );
    expect(
      content.contains("tags: (json['tags'] as List).cast<String>(),"),
      isTrue,
    );
    expect(content.contains('createdAt.toIso8601String()'), isTrue);
    expect(content.contains("'tags': tags,"), isTrue);
  });

  test('ModelGenerator generates nullable fields', () async {
    final featureGen = FeatureGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );
    await featureGen.generate('auth');

    final modelGen = ModelGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );
    await modelGen.generate(
      'auth',
      'user',
      fields: ['name:string', 'age:int?'],
    );

    final modelFile = File(
      p.join(
        tempProject.path,
        'lib',
        'features',
        'auth',
        'data',
        'models',
        'user_model.dart',
      ),
    );
    final content = modelFile.readAsStringSync();
    expect(content.contains('final String name;'), isTrue);
    expect(content.contains('final int? age;'), isTrue);
    expect(content.contains('required this.name,'), isTrue);
    expect(content.contains('this.age,'), isTrue);
    expect(content.contains("age: json['age'] as int?,"), isTrue);
  });

  test('ModelGenerator throws on invalid field format', () async {
    final featureGen = FeatureGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );
    await featureGen.generate('auth');

    final modelGen = ModelGenerator(
      workingDirectory: tempProject.path,
      templatesRootOverride: projectRoot,
    );

    expect(
      () => modelGen.generate('auth', 'user', fields: ['badformat']),
      throwsA(isA<FormatException>()),
    );
  });
}
