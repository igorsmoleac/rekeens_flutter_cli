class {{class_name}}Entity {
  const {{class_name}}Entity({this.id});

  final String? id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is {{class_name}}Entity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
