import '../models/receipt_record.dart';

String eqJsonlFileName([DateTime? now]) {
  final date = now ?? DateTime.now();
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return 'checkscan-eq-$year-$month-$day.jsonl';
}

String encodeEqJsonl(Iterable<ReceiptRecord> receipts) {
  final buffer = StringBuffer();
  for (final record in receipts) {
    final raw = record.payload.trim();
    buffer.writeln(raw.isNotEmpty ? raw : record.receipt.encode());
  }
  return buffer.toString();
}
