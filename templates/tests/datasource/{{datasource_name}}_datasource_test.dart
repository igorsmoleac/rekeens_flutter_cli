import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/datasources/{{datasource_name}}_datasource.dart';
import 'package:{{project_name}}/features/{{feature_name}}/data/datasources/{{datasource_name}}_datasource_impl.dart';

class _FakeHttpClient extends HttpClient {
  _FakeHttpClient(this._fetchResponse, this._postResponse);

  final Map<String, dynamic> _fetchResponse;
  final int _postResponse;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _FakeHttpClientRequest(_postResponse, jsonEncode(_fetchResponse));
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _FakeHttpClientRequest(200, jsonEncode(_fetchResponse));
  }
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this._statusCode, this._responseBody);

  final int _statusCode;
  final String _responseBody;

  @override
  HttpHeaders headers = _FakeHttpHeaders();

  @override
  void write(Object? object) {
    // Discard written data in tests.
  }

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse(_statusCode, _responseBody);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  ContentType? contentType;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse implements HttpClientResponse {
  _FakeHttpClientResponse(this._statusCode, this._body);

  final int _statusCode;
  final String _body;

  @override
  int get statusCode => _statusCode;

  @override
  Stream<List<int>> transform(
    StreamTransformer<List<int>, List<int>> transformer,
  ) {
    return Stream.value(utf8.encode(_body)).transform(transformer);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('{{class_name}}DataSource', () {
    test('fetchData returns decoded JSON on success', () async {
      final {{class_name}}DataSource dataSource = {{class_name}}DataSourceImpl(
        httpClient: _FakeHttpClient({'key': 'value'}, 201),
      );

      final result = await dataSource.fetchData();

      expect(result, {'key': 'value'});
    });

    test('fetchData throws on non-200 status', () async {
      final {{class_name}}DataSource dataSource = {{class_name}}DataSourceImpl(
        httpClient: _FakeHttpClient({}, 404),
      );

      expect(
        () => dataSource.fetchData(),
        throwsA(isA<Exception>()),
      );
    });

    test('postData completes on 201 Created', () async {
      final {{class_name}}DataSource dataSource = {{class_name}}DataSourceImpl(
        httpClient: _FakeHttpClient({}, 201),
      );

      await dataSource.postData({'name': 'test'});

      // No exception = success.
    });
  });
}
