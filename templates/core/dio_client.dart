import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'network_config.dart';

class DioClient {
  DioClient(NetworkConfig config) {
    _dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        headers: config.headers,
      ),
    );
    _dio.interceptors.add(_AuthInterceptor(config.tokenProvider));
    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  late final Dio _dio;

  Dio get dio => _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async {
    return _request(
      () => _dio.get<T>(
        path,
        queryParameters: query,
        options: Options(headers: headers),
      ),
    );
  }

  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _request(
      () => _dio.post<T>(
        path,
        data: body,
        options: Options(headers: headers),
      ),
    );
  }

  Future<T> _request<T>(Future<Response<T>> Function() call) async {
    try {
      final response = await call();
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Request failed',
        statusCode: e.response?.statusCode,
        responseBody: e.response?.data?.toString(),
      );
    }
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokenProvider);

  final TokenProvider? _tokenProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
