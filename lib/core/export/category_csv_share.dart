import 'dart:io';

import 'category_csv.dart';
import 'export_file.dart';

Future<void> shareCategoryCsv({
  required Iterable<CategoryExportRow> rows,
  required String subject,
  DateTime? now,
  String Function(String key)? categoryName,
  Future<Directory> Function()? temporaryDirectory,
  ShareFile? shareFile,
}) {
  return shareExport(
    name: categoryCsvFileName(now),
    contents: encodeCategoryCsv(rows, categoryName: categoryName),
    mimeType: 'text/csv',
    subject: subject,
    temporaryDirectory: temporaryDirectory,
    shareFile: shareFile,
  );
}
