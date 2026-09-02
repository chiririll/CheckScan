import 'dart:convert';
import 'dart:io';

import 'package:checkscan/core/export/eq_jsonl.dart';
import 'package:checkscan/core/export/eq_jsonl_share.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

ReceiptRecord _record({required String id, String? payload, double total = 10}) {
  final receipt = EqReceipt(
    id: id,
    issuedAt: DateTime.utc(2026, 8, 28, 15, 42),
    currency: 'RUB',
    receiptType: 'sale',
    merchantName: 'Магнит',
    grandTotal: total,
  );
  return ReceiptRecord(
    id: id,
    qrHash: 'h:$id',
    adapterId: 'eq_payload',
    status: ReceiptStatus.ok,
    issuedAt: receipt.issuedAt,
    merchantName: receipt.merchantName,
    grandTotal: receipt.grandTotal,
    currency: receipt.currency,
    itemCount: 0,
    payload: payload ?? receipt.encode(),
    scannedAt: receipt.issuedAt,
    rawQr: '{}',
  );
}

void main() {
  test('eqJsonlFileName uses the local calendar date', () {
    expect(eqJsonlFileName(DateTime(2026, 9, 2)), 'checkscan-eq-2026-09-02.jsonl');
  });

  test('encodeEqJsonl returns empty string for no receipts', () {
    expect(encodeEqJsonl(const []), '');
  });

  test('encodeEqJsonl writes one JSON object per line', () {
    final first = '{"eq_version":"1.0.0","receipt":{"id":"a"}}';
    final second = '{"eq_version":"1.0.0","receipt":{"id":"b"}}';
    final jsonl = encodeEqJsonl([
      _record(id: 'a', payload: first),
      _record(id: 'b', payload: second),
    ]);

    expect(jsonl, '$first\n$second\n');
    final lines = const LineSplitter().convert(jsonl.trimRight());
    expect(lines, hasLength(2));
    expect(jsonDecode(lines[0]), {'eq_version': '1.0.0', 'receipt': {'id': 'a'}});
    expect(jsonDecode(lines[1]), {'eq_version': '1.0.0', 'receipt': {'id': 'b'}});
  });

  test('encodeEqJsonl keeps stored payload as-is', () {
    const payload = '{"eq_version":"1.0.0","receipt":{"id":"raw","custom":true}}';
    expect(encodeEqJsonl([_record(id: 'raw', payload: payload)]), '$payload\n');
  });

  test('encodeEqJsonl falls back to encode when payload is empty', () {
    final record = _record(id: 'fallback', payload: '  ');
    final jsonl = encodeEqJsonl([record]);
    expect(jsonl, '${record.receipt.encode()}\n');
    expect(jsonDecode(jsonl.trim()), containsPair('eq_version', '1.0.0'));
  });

  test('writeEqJsonlFile writes the named file', () async {
    final dir = Directory.systemTemp.createTempSync('checkscan_export_');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    final file = await writeEqJsonlFile(
      receipts: [_record(id: 'a', payload: '{"id":"a"}')],
      directory: dir,
      now: DateTime(2026, 9, 2),
    );

    expect(p.basename(file.path), 'checkscan-eq-2026-09-02.jsonl');
    expect(file.readAsStringSync(), '{"id":"a"}\n');
  });
}
