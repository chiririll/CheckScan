import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'category_csv.dart';

Future<File> writeCategoryCsvFile({
  required Iterable<CategoryExportRow> rows,
  required Directory directory,
  DateTime? now,
  String Function(String key)? categoryName,
}) async {
  final file = File(p.join(directory.path, categoryCsvFileName(now)));
  await file.writeAsString(encodeCategoryCsv(rows, categoryName: categoryName));
  return file;
}

Future<void> shareCategoryCsv({
  required Iterable<CategoryExportRow> rows,
  required String subject,
  DateTime? now,
  String Function(String key)? categoryName,
  Future<Directory> Function()? temporaryDirectory,
  Future<void> Function(String path, String subject)? shareFile,
}) async {
  final directory = await (temporaryDirectory ?? getTemporaryDirectory)();
  final file = await writeCategoryCsvFile(
    rows: rows,
    directory: directory,
    now: now,
    categoryName: categoryName,
  );
  final share = shareFile ?? _shareFile;
  await share(file.path, subject);
}

Future<void> _shareFile(String path, String subject) {
  return SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: 'text/csv')],
      subject: subject,
    ),
  );
}
