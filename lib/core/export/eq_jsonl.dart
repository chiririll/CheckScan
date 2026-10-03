import '../models/receipt_record.dart';
import 'export_file.dart';

String eqJsonlFileName([DateTime? now]) => datedExportName('eq', 'jsonl', now);

/// One eQ JSON object per line. The stored payload is kept verbatim when present.
String encodeEqJsonl(Iterable<ReceiptRecord> receipts) {
  final buffer = StringBuffer();
  for (final record in receipts) {
    final raw = record.payload.trim();
    buffer.writeln(raw.isNotEmpty ? raw : record.receipt.encode());
  }
  return buffer.toString();
}
