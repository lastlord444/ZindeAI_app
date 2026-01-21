class AppBaseException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppBaseException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppBaseException: $message (code: $code)';
}

class NetworkException extends AppBaseException {
  NetworkException(super.message, {super.details})
      : super(code: 'NETWORK_ERROR');
}

class AuthException extends AppBaseException {
  AuthException(super.message) : super(code: 'AUTH_ERROR');
}

class ServerException extends AppBaseException {
  final int? statusCode;
  ServerException(super.message, {this.statusCode, super.details})
      : super(code: 'SERVER_ERROR');
}

class ValidationException extends AppBaseException {
  ValidationException(super.message, {super.details})
      : super(code: 'VALIDATION_ERROR');
}
