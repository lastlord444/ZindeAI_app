class AppBaseException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppBaseException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppBaseException: $message (code: $code)';
}

class NetworkException extends AppBaseException {
  NetworkException(String message, {dynamic details})
      : super(message, code: 'NETWORK_ERROR', details: details);
}

class AuthException extends AppBaseException {
  AuthException(String message)
      : super(message, code: 'AUTH_ERROR');
}

class ServerException extends AppBaseException {
  final int? statusCode;
  ServerException(String message, {this.statusCode, dynamic details})
      : super(message, code: 'SERVER_ERROR', details: details);
}

class ValidationException extends AppBaseException {
  ValidationException(String message, {dynamic details})
      : super(message, code: 'VALIDATION_ERROR', details: details);
}
