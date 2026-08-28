abstract class {{class_name}}Repository {
  Future<List<String>> getItems();
}

class {{class_name}}RepositoryImpl implements {{class_name}}Repository {
  @override
  Future<List<String>> getItems() async {
    // TODO: implement data fetching
    return [];
  }
}