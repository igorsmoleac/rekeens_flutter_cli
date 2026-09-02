import 'dart:convert';
import 'dart:io';

import '{{datasource_name}}_datasource.dart';

class {{class_name}}DataSourceImpl implements {{class_name}}DataSource {
  {{class_name}}DataSourceImpl({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  @override
  Future<Map<String, dynamic>> fetchData() async {
    final request = await _httpClient.getUrl(
      Uri.parse('https://api.example.com/{{datasource_name}}'),
    );
    final response = await request.close();

    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Failed to fetch data: HTTP ${response.statusCode}',
      );
    }

    final body = await response.transform(utf8.decoder).join();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  @override
  Future<void> postData(Map<String, dynamic> data) async {
    final request = await _httpClient.postUrl(
      Uri.parse('https://api.example.com/{{datasource_name}}'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(data));
    final response = await request.close();

    if (response.statusCode != HttpStatus.ok &&
        response.statusCode != HttpStatus.created) {
      throw Exception(
        'Failed to post data: HTTP ${response.statusCode}',
      );
    }
  }
}
