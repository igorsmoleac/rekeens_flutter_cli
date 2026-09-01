import 'failure.dart';
import '../network/api_exception.dart';

Failure mapExceptionToFailure(Object exception) {
  if (exception is ApiException) {
    final statusCode = exception.statusCode;
    if (statusCode == null) {
      return NetworkFailure(message: exception.message);
    }
    if (statusCode >= 500) {
      return ServerFailure(message: exception.message, statusCode: statusCode);
    }
    if (statusCode >= 400) {
      return ClientFailure(message: exception.message, statusCode: statusCode);
    }
    return NetworkFailure(message: exception.message);
  }

  if (exception is TypeError) {
    return const UnknownFailure(message: 'Unexpected type error');
  }

  return UnknownFailure(message: exception.toString());
}
