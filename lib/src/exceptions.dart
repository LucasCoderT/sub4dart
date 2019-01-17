/// The Base Exception for all errors in this library.
class BaseException implements Exception {
  final String message;
  final int code;

  BaseException(this.message, this.code);
}

/// 	Required parameter is missing.
class MissingRequiredArgument extends BaseException {
  MissingRequiredArgument(String message, int code) : super(message, code);
}

/// 	Incompatible Subsonic REST protocol version. Client must upgrade.
class ClientOutOfDate extends BaseException {
  ClientOutOfDate(String message, int code) : super(message, code);
}

/// Incompatible Subsonic REST protocol version. Server must upgrade.
class ServerOutOfDate extends BaseException {
  ServerOutOfDate(String message, int code) : super(message, code);
}

/// Wrong username or password.
class InvalidCredentials extends BaseException {
  InvalidCredentials(String message, int code) : super(message, code);
}

/// 	Token authentication not supported for LDAP users.
class LDAPNotSupported extends BaseException {
  LDAPNotSupported(String message, int code) : super(message, code);
}

/// User is not authorized for the given operation.
class UnAuthorized extends BaseException {
  UnAuthorized(String message, int code) : super(message, code);
}

/// 	The trial period for the Subsonic server is over. Please upgrade to Subsonic Premium. Visit subsonic.org for details.
class RequiresPremium extends BaseException {
  RequiresPremium(String message, int code) : super(message, code);
}

/// The requested data was not found.
class DataNotFoundException extends BaseException {
  DataNotFoundException(String message, int code) : super(message, code);
}
