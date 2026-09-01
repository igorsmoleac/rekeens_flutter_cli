/// Returns the current bearer token, or `null` when no session is active.
typedef TokenProvider = String? Function();

class NetworkConfig {
  const NetworkConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 10),
    this.headers = const {},
    this.tokenProvider,
  });

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Map<String, String> headers;
  final TokenProvider? tokenProvider;
}
