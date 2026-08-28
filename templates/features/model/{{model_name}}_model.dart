class {{class_name}}Model {
  final int id;
  final String name;

  const {{class_name}}Model({
    required this.id,
    required this.name,
  });

  factory {{class_name}}Model.fromJson(Map<String, dynamic> json) {
    return {{class_name}}Model(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}