import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

typedef ShareFile = Future<void> Function(String path, String subject);

/// `YYYY-MM-DD`, independent of locale.
String isoDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// `checkscan-<kind>-YYYY-MM-DD.<extension>`.
String datedExportName(String kind, String extension, [DateTime? now]) {
  return 'checkscan-$kind-${isoDate(now ?? DateTime.now())}.$extension';
}

Future<File> writeExportFile(Directory directory, String name, String contents) async {
  final file = File(p.join(directory.path, name));
  await file.writeAsString(contents);
  return file;
}

/// Writes [contents] into a temp file and opens the system share sheet.
Future<void> shareExport({
  required String name,
  required String contents,
  required String mimeType,
  required String subject,
  Future<Directory> Function()? temporaryDirectory,
  ShareFile? shareFile,
}) async {
  final directory = await (temporaryDirectory ?? getTemporaryDirectory)();
  final file = await writeExportFile(directory, name, contents);
  final share = shareFile ??
      (path, subject) => SharePlus.instance.share(
            ShareParams(files: [XFile(path, mimeType: mimeType)], subject: subject),
          );
  await share(file.path, subject);
}
