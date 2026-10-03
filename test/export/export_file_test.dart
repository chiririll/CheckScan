import 'dart:io';

import 'package:checkscan/core/export/export_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isoDate pads month and day', () {
    expect(isoDate(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
  });

  test('datedExportName builds the shared file name scheme', () {
    expect(datedExportName('eq', 'jsonl', DateTime(2026, 10, 3)), 'checkscan-eq-2026-10-03.jsonl');
  });

  test('shareExport writes the file and hands its path to the sharer', () async {
    final directory = await Directory.systemTemp.createTemp('checkscan_export');
    addTearDown(() => directory.delete(recursive: true));
    String? sharedPath;
    String? sharedSubject;

    await shareExport(
      name: 'out.txt',
      contents: 'hello',
      mimeType: 'text/plain',
      subject: 'subj',
      temporaryDirectory: () async => directory,
      shareFile: (path, subject) async {
        sharedPath = path;
        sharedSubject = subject;
      },
    );

    expect(sharedSubject, 'subj');
    expect(File(sharedPath!).readAsStringSync(), 'hello');
  });
}
