import 'dart:io';

import '../models/receipt_record.dart';
import 'eq_jsonl.dart';
import 'export_file.dart';

Future<File> writeEqJsonlFile({
  required Iterable<ReceiptRecord> receipts,
  required Directory directory,
  DateTime? now,
}) {
  return writeExportFile(directory, eqJsonlFileName(now), encodeEqJsonl(receipts));
}

Future<void> shareEqJsonl({
  required Iterable<ReceiptRecord> receipts,
  required String subject,
  DateTime? now,
  Future<Directory> Function()? temporaryDirectory,
  ShareFile? shareFile,
}) {
  return shareExport(
    name: eqJsonlFileName(now),
    contents: encodeEqJsonl(receipts),
    mimeType: 'application/jsonl',
    subject: subject,
    temporaryDirectory: temporaryDirectory,
    shareFile: shareFile,
  );
}
