enum PoilinkErrorCode {
  notInitialized(1001),
  configurationError(1002),
  authenticationFailed(1003),
  network(1004),
  invalidResponse(1005),
  storageError(1006),
  timeout(1007),
  connectionRefused(1008),
  httpServerError(1009),
  parseError(1010),
  validationError(1011),
  authRecoverable(1012),
  alreadyAuthenticated(1013),
  renderProcessGone(1014);

  const PoilinkErrorCode(this.value);

  final int value;

  static PoilinkErrorCode? fromValue(int value) {
    for (final code in PoilinkErrorCode.values) {
      if (code.value == value) return code;
    }
    return null;
  }
}

class PoilinkException implements Exception {
  const PoilinkException(this.errorCodeValue, this.message);

  final int errorCodeValue;
  final String message;

  PoilinkErrorCode? get errorCode => PoilinkErrorCode.fromValue(errorCodeValue);

  @override
  String toString() =>
      'PoilinkException: [${errorCode ?? errorCodeValue}($errorCodeValue)] $message';
}
