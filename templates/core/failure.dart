sealed class Failure {
  const Failure({required this.message});

  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, this.statusCode});

  final int? statusCode;
}

class ClientFailure extends Failure {
  const ClientFailure({required super.message, this.statusCode});

  final int? statusCode;
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class UnknownFailure extends Failure {
  const UnknownFailure({required super.message});
}
