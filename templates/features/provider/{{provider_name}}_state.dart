class {{class_name}}State {
  const {{class_name}}State({this.count = 0, this.isLoading = false});

  final int count;
  final bool isLoading;

  {{class_name}}State copyWith({int? count, bool? isLoading}) {
    return {{class_name}}State(
      count: count ?? this.count,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
