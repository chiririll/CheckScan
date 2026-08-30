class UnknownReceiptFormat implements Exception {
  const UnknownReceiptFormat();
}

class AdapterParseException implements Exception {
  const AdapterParseException(this.adapterId, this.message);
  final String adapterId;
  final String message;

  @override
  String toString() => 'AdapterParseException($adapterId): $message';
}
