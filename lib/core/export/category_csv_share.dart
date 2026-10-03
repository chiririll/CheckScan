import 'dart:io';

import 'category_csv.dart';
import 'export_file.dart';

Future<File> writeCategoryCsvFile({
  required Iterable<CategoryExportRow> rows,
  required Directory directory,
  DateTime? now,
  String Function(String key)? categoryName,
}) {
  return writeExportFile(directory, categoryCsvFileName(now), encodeCategoryCsv(rows, categoryName: categoryName));
}

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
