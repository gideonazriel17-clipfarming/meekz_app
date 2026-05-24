class MeekzException implements Exception {
  const MeekzException(this.message);

  final String message;

  @override
  String toString() => 'MeekzException: $message';
}
