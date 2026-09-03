import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rekeens_flutter_cli/generators/model_generator.dart';
import 'package:rekeens_flutter_cli/generators/screen_generator.dart';
import 'package:test/test.dart';

import 'helpers/generator_test_helper.dart';

void main() {
  final h = GeneratorTestHelper()..register();

  test('FeatureGenerator creates feature structure', () async {
    final generator = h.featureGenerator();
    await generator.generate('auth');

    final featureDir = Directory(
      p.join(h.tempProject.path, 'lib', 'features', 'auth'),
    );
    expect(featureDir.existsSync(), isTrue);
    expect(Directory(p.join(featureDir.path, 'data')).existsSync(), isTrue);
    expect(Directory(p.join(featureDir.path, 'domain')).existsSync(), isTrue);
    expect(
      File(
        p.join(featureDir.path, 'presentation', 'pages', 'auth_page.dart'),
      ).existsSync(),
      isTrue,
    );
  });

  test('FeatureGenerator adds route to router.dart', () async {
    final generator = h.featureGenerator();
    await generator.generate('auth');

    final routerFile = File(
      p.join(h.tempProject.path, 'lib', 'app', 'router.dart'),
    );
    final content = routerFile.readAsStringSync();
    expect(content.contains("path: '/auth'"), isTrue);
    expect(content.contains('const AuthPage()'), isTrue);
    expect(
      content.contains(
        "import '../features/auth/presentation/pages/auth_page.dart';",
      ),
      isTrue,
    );
  });

  test('ScreenGenerator creates screen file', () async {
    await h.withAuthFeature(() async {
      final screenGen = ScreenGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await screenGen.generate('auth', 'login');

      final screenFile = File(
        p.join(
          h.tempProject.path,
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
  });

  test('ScreenGenerator adds nested route to router.dart', () async {
    await h.withAuthFeature(() async {
      final screenGen = ScreenGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await screenGen.generate('auth', 'login');

      final routerFile = File(
        p.join(h.tempProject.path, 'lib', 'app', 'router.dart'),
      );
      final content = routerFile.readAsStringSync();
      expect(content.contains("path: '/auth/login'"), isTrue);
      expect(content.contains('const LoginScreen()'), isTrue);
      expect(
        content.contains(
          "import '../features/auth/presentation/pages/login_screen.dart';",
        ),
        isTrue,
      );
    });
  });

  test('ModelGenerator creates model file', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await modelGen.generate('auth', 'user');

      final modelFile = File(
        p.join(
          h.tempProject.path,
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
  });

  test('ModelGenerator generates fields from arguments', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await modelGen.generate(
        'auth',
        'user',
        fields: ['name:string', 'age:int', 'price:double', 'active:bool'],
      );

      final modelFile = File(
        p.join(
          h.tempProject.path,
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
  });

  test('ModelGenerator generates DateTime and List fields', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await modelGen.generate(
        'auth',
        'user',
        fields: ['createdAt:DateTime', 'tags:List<String>'],
      );

      final modelFile = File(
        p.join(
          h.tempProject.path,
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
  });

  test('ModelGenerator generates nullable fields', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await modelGen.generate(
        'auth',
        'user',
        fields: ['name:string', 'age:int?'],
      );

      final modelFile = File(
        p.join(
          h.tempProject.path,
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
  });

  test('ModelGenerator throws on invalid field format', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );

      expect(
        () => modelGen.generate('auth', 'user', fields: ['badformat']),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('ModelGenerator generates custom model field with import', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await modelGen.generate(
        'auth',
        'user',
        fields: ['name:string', 'profile:UserProfile'],
      );

      final modelFile = File(
        p.join(
          h.tempProject.path,
          'lib',
          'features',
          'auth',
          'data',
          'models',
          'user_model.dart',
        ),
      );
      final content = modelFile.readAsStringSync();
      expect(content.contains("import 'user_profile.dart';"), isTrue);
      expect(content.contains('final UserProfile profile;'), isTrue);
      expect(
        content.contains(
          'profile: UserProfile.fromJson(json[\'profile\'] as Map<String, dynamic>),',
        ),
        isTrue,
      );
      expect(content.contains("'profile': profile.toJson(),"), isTrue);
    });
  });

  test('ModelGenerator generates nullable custom model field', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await modelGen.generate(
        'auth',
        'user',
        fields: ['name:string', 'profile:UserProfile?'],
      );

      final modelFile = File(
        p.join(
          h.tempProject.path,
          'lib',
          'features',
          'auth',
          'data',
          'models',
          'user_model.dart',
        ),
      );
      final content = modelFile.readAsStringSync();
      expect(content.contains('final UserProfile? profile;'), isTrue);
      expect(
        content.contains(
          "profile: json['profile'] == null ? null : "
          "UserProfile.fromJson(json['profile'] as Map<String, dynamic>),",
        ),
        isTrue,
      );
      expect(content.contains("'profile': profile?.toJson(),"), isTrue);
    });
  });

  test('ModelGenerator generates List<CustomModel> field with import', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await modelGen.generate(
        'auth',
        'user',
        fields: ['name:string', 'items:List<OrderItem>'],
      );

      final modelFile = File(
        p.join(
          h.tempProject.path,
          'lib',
          'features',
          'auth',
          'data',
          'models',
          'user_model.dart',
        ),
      );
      final content = modelFile.readAsStringSync();
      expect(content.contains("import 'order_item.dart';"), isTrue);
      expect(content.contains('final List<OrderItem> items;'), isTrue);
      expect(
        content.contains(
          "items: (json['items'] as List)"
          '.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),',
        ),
        isTrue,
      );
      expect(
        content.contains("'items': items.map((e) => e.toJson()).toList(),"),
        isTrue,
      );
    });
  });

  test('ModelGenerator generates enum field with import', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await modelGen.generate(
        'auth',
        'user',
        fields: ['name:string', 'role:enum Role'],
      );

      final modelFile = File(
        p.join(
          h.tempProject.path,
          'lib',
          'features',
          'auth',
          'data',
          'models',
          'user_model.dart',
        ),
      );
      final content = modelFile.readAsStringSync();
      expect(content.contains("import 'role.dart';"), isTrue);
      expect(content.contains('final Role role;'), isTrue);
      expect(
        content.contains("role: Role.values.byName(json['role'] as String),"),
        isTrue,
      );
      expect(content.contains("'role': role.name,"), isTrue);
    });
  });

  test('ModelGenerator generates nullable enum field', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await modelGen.generate(
        'auth',
        'user',
        fields: ['name:string', 'role:enum Role?'],
      );

      final modelFile = File(
        p.join(
          h.tempProject.path,
          'lib',
          'features',
          'auth',
          'data',
          'models',
          'user_model.dart',
        ),
      );
      final content = modelFile.readAsStringSync();
      expect(content.contains('final Role? role;'), isTrue);
      expect(content.contains('this.role,'), isTrue);
      expect(
        content.contains(
          "role: json['role'] == null ? null : "
          "Role.values.byName(json['role'] as String),",
        ),
        isTrue,
      );
      expect(content.contains("'role': role?.name,"), isTrue);
    });
  });

  test('ModelGenerator generates Map<String, dynamic> field', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await modelGen.generate(
        'auth',
        'user',
        fields: ['name:string', 'metadata:Map<String, dynamic>'],
      );

      final modelFile = File(
        p.join(
          h.tempProject.path,
          'lib',
          'features',
          'auth',
          'data',
          'models',
          'user_model.dart',
        ),
      );
      final content = modelFile.readAsStringSync();
      expect(content.contains('final Map<String, dynamic> metadata;'), isTrue);
      expect(
        content.contains(
          "metadata: Map<String, dynamic>.from(json['metadata'] as Map),",
        ),
        isTrue,
      );
      expect(content.contains("'metadata': metadata,"), isTrue);
      // No import for Map.
      expect(content.contains("import 'metadata"), isFalse);
    });
  });

  test('ModelGenerator deduplicates imports for same custom type', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await modelGen.generate(
        'auth',
        'user',
        fields: ['primary:UserProfile', 'secondary:UserProfile?'],
      );

      final modelFile = File(
        p.join(
          h.tempProject.path,
          'lib',
          'features',
          'auth',
          'data',
          'models',
          'user_model.dart',
        ),
      );
      final content = modelFile.readAsStringSync();
      // Only one import line for user_profile.dart.
      final importCount = "import 'user_profile.dart';"
          .allMatches(content)
          .length;
      expect(importCount, 1);
    });
  });

  // --- Test generation ---

  test('FeatureGenerator creates page test file by default', () async {
    final generator = h.featureGenerator();
    await generator.generate('auth');

    final testFile = File(
      p.join(
        h.tempProject.path,
        'test',
        'features',
        'auth',
        'presentation',
        'pages',
        'auth_page_test.dart',
      ),
    );
    expect(testFile.existsSync(), isTrue);
    final content = testFile.readAsStringSync();
    expect(content.contains("import 'package:test/features/auth"), isTrue);
    expect(content.contains('AuthPage'), isTrue);
  });

  test('FeatureGenerator skips test file when withTests=false', () async {
    final generator = h.featureGenerator();
    await generator.generate('auth', withTests: false);

    final testFile = File(
      p.join(
        h.tempProject.path,
        'test',
        'features',
        'auth',
        'presentation',
        'pages',
        'auth_page_test.dart',
      ),
    );
    expect(testFile.existsSync(), isFalse);
  });

  test('ScreenGenerator creates screen test file by default', () async {
    await h.withAuthFeature(() async {
      final screenGen = ScreenGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await screenGen.generate('auth', 'login');

      final testFile = File(
        p.join(
          h.tempProject.path,
          'test',
          'features',
          'auth',
          'presentation',
          'pages',
          'login_screen_test.dart',
        ),
      );
      expect(testFile.existsSync(), isTrue);
      final content = testFile.readAsStringSync();
      expect(content.contains('LoginScreen'), isTrue);
      expect(content.contains('testWidgets'), isTrue);
    });
  });

  test('ScreenGenerator skips test file when withTests=false', () async {
    await h.withAuthFeature(() async {
      final screenGen = ScreenGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await screenGen.generate('auth', 'login', withTests: false);

      final testFile = File(
        p.join(
          h.tempProject.path,
          'test',
          'features',
          'auth',
          'presentation',
          'pages',
          'login_screen_test.dart',
        ),
      );
      expect(testFile.existsSync(), isFalse);
    });
  });

  test('ModelGenerator creates model test file by default', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await modelGen.generate('auth', 'user');

      final testFile = File(
        p.join(
          h.tempProject.path,
          'test',
          'features',
          'auth',
          'data',
          'models',
          'user_model_test.dart',
        ),
      );
      expect(testFile.existsSync(), isTrue);
      final content = testFile.readAsStringSync();
      expect(content.contains('UserModel'), isTrue);
      expect(content.contains('fromJson'), isTrue);
      expect(content.contains('toJson'), isTrue);
    });
  });

  test('ModelGenerator skips test file when withTests=false', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await modelGen.generate('auth', 'user', withTests: false);

      final testFile = File(
        p.join(
          h.tempProject.path,
          'test',
          'features',
          'auth',
          'data',
          'models',
          'user_model_test.dart',
        ),
      );
      expect(testFile.existsSync(), isFalse);
    });
  });

  test('ModelGenerator dry-run logs test file creation', () async {
    await h.withAuthFeature(() async {
      final modelGen = ModelGenerator(
        workingDirectory: h.tempProject.path,
        templatesRootOverride: h.projectRoot,
      );
      await modelGen.generate('auth', 'user', dryRun: true);

      final testFile = File(
        p.join(
          h.tempProject.path,
          'test',
          'features',
          'auth',
          'data',
          'models',
          'user_model_test.dart',
        ),
      );
      expect(testFile.existsSync(), isFalse);
    });
  });
}
