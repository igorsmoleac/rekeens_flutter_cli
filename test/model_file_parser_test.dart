import 'package:rekeens_flutter_cli/utils/model_fields.dart';
import 'package:rekeens_flutter_cli/utils/model_file_parser.dart';
import 'package:test/test.dart';

const _modelSource = '''
import 'address_model.dart';
import 'role.dart';

class UserModel {
  final String name;
  final int? age;
  final double balance;
  final bool active;
  final DateTime createdAt;
  final List<String> tags;
  final AddressModel address;
  final AddressModel? backupAddress;
  final List<AddressModel> orders;
  final Role role;
  final Role? primaryRole;
  final Map<String, dynamic> meta;

  const UserModel({
    required this.name,
    required this.age,
    required this.balance,
    required this.active,
    required this.createdAt,
    required this.tags,
    required this.address,
    this.backupAddress,
    required this.role,
    this.primaryRole,
    required this.meta,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] as String,
      age: json['age'] as int?,
      balance: (json['balance'] as num).toDouble(),
      active: json['active'] as bool,
      createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
      tags: (json['tags'] as List).cast<String>(),
      address: AddressModel.fromJson(json['address'] as Map<String, dynamic>),
      backupAddress: json['backupAddress'] == null ? null : AddressModel.fromJson(json['backupAddress'] as Map<String, dynamic>),
      orders: (json['orders'] as List).map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList(),
      role: Role.values.byName(json['role'] as String),
      primaryRole: json['primaryRole'] == null ? null : Role.values.byName(json['primaryRole'] as String),
      meta: Map<String, dynamic>.from(json['meta'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'balance': balance,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'address': address.toJson(),
      'backupAddress': backupAddress?.toJson(),
      'orders': orders.map((e) => e.toJson()).toList(),
      'role': role.name,
      'primaryRole': primaryRole?.name,
      'meta': meta,
    };
  }
}
''';

void main() {
  group('parseModelFileSource', () {
    test('parses all field declarations in order', () {
      final parsed = parseModelFileSource(_modelSource);

      expect(parsed.fields.map((f) => f.name), [
        'name',
        'age',
        'balance',
        'active',
        'createdAt',
        'tags',
        'address',
        'backupAddress',
        'orders',
        'role',
        'primaryRole',
        'meta',
      ]);
    });

    test('reconstructs primitive field types', () {
      final byName = {
        for (final f in parseModelFileSource(_modelSource).fields) f.name: f,
      };

      expect(byName['name']!.dartType, 'String');
      expect(byName['balance']!.dartType, 'double');
      expect(byName['active']!.dartType, 'bool');
      expect(byName['age']!.dartType, 'int?');
      expect(byName['age']!.isNullable, isTrue);
    });

    test('reconstructs DateTime field', () {
      final createdAt = _field('createdAt');
      expect(createdAt.category, FieldCategory.dateTime);
      expect(createdAt.dartType, 'DateTime');
    });

    test('reconstructs list of primitives', () {
      final tags = _field('tags');
      expect(tags.category, FieldCategory.listPrimitive);
      expect(tags.dartType, 'List<String>');
      expect(tags.innerType, 'String');
    });

    test('reconstructs custom model field with import path', () {
      final address = _field('address');
      expect(address.category, FieldCategory.custom);
      expect(address.baseType, 'AddressModel');
      expect(address.importPath, 'address_model.dart');
    });

    test('reconstructs nullable custom model field', () {
      final backup = _field('backupAddress');
      expect(backup.dartType, 'AddressModel?');
      expect(backup.isNullable, isTrue);
      expect(backup.importPath, 'address_model.dart');
    });

    test('reconstructs List<CustomModel> field', () {
      final orders = _field('orders');
      expect(orders.category, FieldCategory.listCustom);
      expect(orders.dartType, 'List<AddressModel>');
      expect(orders.innerType, 'AddressModel');
      expect(orders.importPath, 'address_model.dart');
    });

    test('reconstructs enum fields via fromJson hint', () {
      final role = _field('role');
      final primaryRole = _field('primaryRole');

      expect(role.category, FieldCategory.enumType);
      expect(role.baseType, 'Role');
      expect(role.importPath, 'role.dart');
      expect(primaryRole.category, FieldCategory.enumType);
      expect(primaryRole.dartType, 'Role?');
    });

    test('reconstructs Map<String, dynamic> field', () {
      final meta = _field('meta');
      expect(meta.category, FieldCategory.map);
      expect(meta.dartType, 'Map<String, dynamic>');
    });

    test('parses model without imports', () {
      const source = '''
class PointModel {
  final int x;
  final int y;

  const PointModel({
    required this.x,
    required this.y,
  });

  factory PointModel.fromJson(Map<String, dynamic> json) {
    return PointModel(
      x: json['x'] as int,
      y: json['y'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }
}
''';
      expect(parseModelFileSource(source).fields.map((f) => f.name), [
        'x',
        'y',
      ]);
    });

    test('throws when source has no field declarations', () {
      expect(
        () => parseModelFileSource('class Empty {}\n'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('No field declarations'),
          ),
        ),
      );
    });

    test('throws with field context for unsupported types', () {
      const source = '''
class WeirdModel {
  final Map<String, int> counts;

  const WeirdModel({required this.counts});

  factory WeirdModel.fromJson(Map<String, dynamic> json) {
    return WeirdModel(counts: json['counts'] as Map<String, int>);
  }
}
''';
      expect(
        () => parseModelFileSource(source),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Cannot parse field "counts"'),
          ),
        ),
      );
    });

    test('throws on duplicate fields in source', () {
      const source = '''
class DupModel {
  final int id;
  final int id;

  const DupModel({required this.id});

  factory DupModel.fromJson(Map<String, dynamic> json) {
    return DupModel(id: json['id'] as int);
  }
}
''';
      expect(
        () => parseModelFileSource(source),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Duplicate field "id"'),
          ),
        ),
      );
    });
  });
}

ModelField _field(String name) {
  return parseModelFileSource(
    _modelSource,
  ).fields.firstWhere((f) => f.name == name);
}
