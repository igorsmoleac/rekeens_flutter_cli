class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.responseBody,
  });

  final String message;
  final int? statusCode;
  final String? responseBody;

  @override
  String toString() {
    final parts = <String>['ApiException: $message'];
    if (statusCode != null) parts.add('status $statusCode');
    if (responseBody != null) parts.add('body: $responseBody');
    return parts.join(' | ');
  }
}
