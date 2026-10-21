class ApiException implements Exception {
  final int statusCode;
  final String? errorCode;
  final String message;

  const ApiException({
    required this.statusCode,
    this.errorCode,
    required this.message,
  });

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, errorCode: $errorCode, message: $message)';
}
