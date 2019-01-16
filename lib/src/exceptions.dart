class BaseException implements Exception {
  final String message;
  final int code;

  BaseException(this.message, this.code);
}

class DataNotFoundException extends BaseException {
  DataNotFoundException(String message, int code) : super(message, code);
}

class MissingRequiredArgument extends BaseException {
  MissingRequiredArgument(String message, int code) : super(message, code);
}

class ClientOutOfDate extends BaseException {
  ClientOutOfDate(String message, int code) : super(message, code);
}

class ServerOutOfDate extends BaseException {
  ServerOutOfDate(String message, int code) : super(message, code);
}

class InvalidCredentials extends BaseException {
  InvalidCredentials(String message, int code) : super(message, code);
}

class LDAPNotSupported extends BaseException {
  LDAPNotSupported(String message, int code) : super(message, code);
}

class UnAuthorized extends BaseException {
  UnAuthorized(String message, int code) : super(message, code);
}

class RequiresPermiumn extends BaseException {
  RequiresPermiumn(String message, int code) : super(message, code);
}
