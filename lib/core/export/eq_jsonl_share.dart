import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/receipt_record.dart';
import 'eq_jsonl.dart';

Future<File> writeEqJsonlFile({
  required Iterable<ReceiptRecord> receipts,
  required Directory directory,
  DateTime? now,
}) async {
  final file = File(p.join(directory.path, eqJsonlFileName(now)));
  await file.writeAsString(encodeEqJsonl(receipts));
  return file;
}

Future<void> shareEqJsonl({
  required Iterable<ReceiptRecord> receipts,
  required String subject,
  DateTime? now,
  Future<Directory> Function()? temporaryDirectory,
  Future<void> Function(String path, String subject)? shareFile,
}) async {
  final directory = await (temporaryDirectory ?? getTemporaryDirectory)();
  final file = await writeEqJsonlFile(
    receipts: receipts,
    directory: directory,
    now: now,
  );
  final share = shareFile ?? _shareFile;
  await share(file.path, subject);
}

Future<void> _shareFile(String path, String subject) {
  return SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: 'application/jsonl')],
      subject: subject,
    ),
  );
}
