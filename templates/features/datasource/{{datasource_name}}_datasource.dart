abstract class {{class_name}}DataSource {
  Future<Map<String, dynamic>> fetchData();
  Future<void> postData(Map<String, dynamic> data);
}
