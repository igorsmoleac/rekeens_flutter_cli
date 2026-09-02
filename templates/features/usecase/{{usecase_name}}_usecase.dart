class {{class_name}}Params {
  const {{class_name}}Params({this.input});

  final String? input;
}

class {{class_name}}UseCase {
  Future<String> call({{class_name}}Params params) async {
    return params.input ?? '';
  }
}
