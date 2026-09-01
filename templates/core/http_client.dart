import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'network_config.dart';

class HttpClient {
  HttpClient(NetworkConfig config) : _config = config {
    _client = http.Client();
  }

  late final http.Client _client;
  final NetworkConfig _config;

  Future<http.Response> get(String path, {Map<String, String>? headers}) async {
    return _send('GET', path, headers: headers);
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _send('POST', path, body: body, headers: headers);
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _send('PUT', path, body: body, headers: headers);
  }

  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _send('DELETE', path, headers: headers);
  }

  void close() => _client.close();

  Future<http.Response> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${_config.baseUrl}$path');
    final mergedHeaders = <String, String>{..._config.headers, ...?headers};
    final token = _config.tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      mergedHeaders['Authorization'] = 'Bearer $token';
    }

    dev.log('$method $uri', name: 'HttpClient');
    final response = await _switchMethod(
      method,
      uri,
      body: body,
      headers: mergedHeaders,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: 'Request failed',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
    return response;
  }

  Future<http.Response> _switchMethod(
    String method,
    Uri uri, {
    Object? body,
    required Map<String, String> headers,
  }) async {
    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers);
      case 'POST':
        return _client.post(uri, body: body, headers: headers);
      case 'PUT':
        return _client.put(uri, body: body, headers: headers);
      case 'DELETE':
        return _client.delete(uri, headers: headers);
      default:
        throw ApiException(message: 'Unsupported method: $method');
    }
  }
}
