import 'dart:io';

import '../models/receipt_record.dart';
import 'receipts_jsonl.dart';
import 'export_file.dart';

Future<void> shareReceiptsJsonl({
  required Iterable<ReceiptRecord> receipts,
  required String subject,
  DateTime? now,
  Future<Directory> Function()? temporaryDirectory,
  ShareFile? shareFile,
}) {
  return shareExport(
    name: receiptsJsonlFileName(now),
    contents: encodeReceiptsJsonl(receipts),
    mimeType: 'application/jsonl',
    subject: subject,
    temporaryDirectory: temporaryDirectory,
    shareFile: shareFile,
  );
}
