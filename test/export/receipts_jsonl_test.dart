import 'dart:convert';
import 'dart:io';

import 'package:checkscan/core/export/receipts_jsonl.dart';
import 'package:checkscan/core/export/receipts_jsonl_share.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../support/receipt_fixtures.dart';

ReceiptRecord _record({required String id, String? payload, int total = 1000}) {
  final receipt = testReceipt(
    id: id,
    issuedAt: DateTime.utc(2026, 8, 28, 15, 42),
    merchantName: 'Магнит',
    total: total,
  );
  return testRecord(receipt, qrHash: 'h:$id', payload: payload, scannedAt: receipt.issuedAt);
}

void main() {
  test('receiptsJsonlFileName uses the local calendar date', () {
    expect(receiptsJsonlFileName(DateTime(2026, 9, 2)), 'checkscan-receipts-2026-09-02.jsonl');
  });

  test('encodeReceiptsJsonl returns empty string for no receipts', () {
    expect(encodeReceiptsJsonl(const []), '');
  });

  test('encodeReceiptsJsonl writes one CheckScan receipt per line with integer money', () {
    final jsonl = encodeReceiptsJsonl([_record(id: 'a', total: 124750), _record(id: 'b')]);
    final lines = const LineSplitter().convert(jsonl.trimRight());
    expect(lines, hasLength(2));
    final first = jsonDecode(lines[0]) as Map<String, dynamic>;
    expect(first['format'], 'checkscan.receipt');
    expect(first['version'], 1);
    expect(first['id'], 'a');
    expect(first['total'], 124750);
    expect(jsonDecode(lines[1]), containsPair('id', 'b'));
  });

  test('a broken payload is exported from the stored columns', () {
    final jsonl = encodeReceiptsJsonl([_record(id: 'broken', payload: '  ', total: 990)]);
    final row = jsonDecode(jsonl.trim()) as Map<String, dynamic>;
    expect(row['format'], 'checkscan.receipt');
    expect(row['total'], 990);
  });

  test('shareReceiptsJsonl writes the named file and shares it', () async {
    final dir = Directory.systemTemp.createTempSync('checkscan_export_');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    String? shared;
    await shareReceiptsJsonl(
      receipts: [_record(id: 'a')],
      subject: 'eQ',
      now: DateTime(2026, 9, 2),
      temporaryDirectory: () async => dir,
      shareFile: (path, subject) async => shared = path,
    );

    expect(p.basename(shared!), 'checkscan-receipts-2026-09-02.jsonl');
    expect(jsonDecode(File(shared!).readAsStringSync().trim()), containsPair('id', 'a'));
  });
}
