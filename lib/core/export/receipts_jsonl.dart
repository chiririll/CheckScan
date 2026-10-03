import '../models/receipt_record.dart';
import 'export_file.dart';

String receiptsJsonlFileName([DateTime? now]) => datedExportName('receipts', 'jsonl', now);

/// One CheckScan receipt JSON object per line.
String encodeReceiptsJsonl(Iterable<ReceiptRecord> receipts) {
  final buffer = StringBuffer();
  for (final record in receipts) {
    buffer.writeln(record.receipt.encode());
  }
  return buffer.toString();
}
