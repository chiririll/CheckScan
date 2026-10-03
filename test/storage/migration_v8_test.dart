import 'dart:convert';
import 'dart:io';

import 'package:checkscan/core/storage/database.dart';
import 'package:checkscan/core/storage/migrations/migration.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A version-7 database as an older app left it: eQ payloads, REAL totals.
Future<String> _legacyDb(String name, List<Map<String, Object?>> rows) async {
  final path = p.join(Directory.systemTemp.path, name);
  final file = File(path);
  if (file.existsSync()) file.deleteSync();
  final db = await databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 7,
      onCreate: (db, version) => runMigrations(
        db,
        fromExclusive: 0,
        toInclusive: 7,
        steps: [for (final step in checkScanMigrations) if (step.version <= 7) step],
      ),
    ),
  );
  for (final row in rows) {
    await db.insert('receipts', row);
  }
  await db.close();
  return path;
}

Map<String, Object?> _row(String id, {required String payload, required double grandTotal, String currency = 'RUB'}) {
  return {
    'id': id,
    'qr_hash': 'h:$id',
    'adapter_id': 'eq_payload',
    'status': 'ok',
    'issued_at': '2026-08-28T15:42:00.000Z',
    'merchant_name': 'Магнит',
    'grand_total': grandTotal,
    'currency': currency,
    'item_count': 1,
    'payload': payload,
    'scanned_at': '2026-08-28T15:50:00.000Z',
    'raw_qr': '{}',
    'last_status': 200,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('v8 turns eQ float amounts into exact integer minor units', () async {
    final eq = jsonEncode({
      'eq_version': '1.0.0',
      'receipt': {
        'id': 'r1',
        'issued_at': '2026-08-28T15:42:00Z',
        'currency': 'RUB',
        'receipt_type': 'refund',
        'merchant': {'name': 'Магнит', 'tax_id': '7707'},
        'items': [
          {'description': 'Сыр', 'quantity': 0.523, 'unit_price': 599.99, 'total_price': 313.79},
        ],
        'totals': {'grand_total': 89.99},
        'extensions': {'checkscan.provider_label': 'RU'},
      },
    });
    final path = await _legacyDb('checkscan_v8_eq.db', [_row('r1', payload: eq, grandTotal: 89.99)]);

    final database = CheckScanDatabase(resolvePath: () async => path);
    final record = (await ReceiptRepository(database: database).listAll()).single;
    await database.close();

    expect(record.total, 8999);
    expect(jsonDecode(record.payload)['format'], 'checkscan.receipt');
    final receipt = record.receipt;
    expect(receipt.total, 8999);
    expect(receipt.type, 'refund');
    expect(receipt.taxId, '7707');
    expect(receipt.items.single.name, 'Сыр');
    expect(receipt.items.single.quantity, 0.523);
    expect(receipt.items.single.price, 59999);
    expect(receipt.items.single.sum, 31379);
    expect(record.providerLabel, 'RU');
  });

  test('v8 keeps a receipt with an unreadable payload using its columns', () async {
    final path = await _legacyDb('checkscan_v8_broken.db', [
      _row('r2', payload: 'not json', grandTotal: 1247.5, currency: 'RSD'),
    ]);

    final database = CheckScanDatabase(resolvePath: () async => path);
    final record = (await ReceiptRepository(database: database).listAll()).single;
    final columns = await (await database.database).rawQuery('PRAGMA table_info(receipts)');
    await database.close();

    expect(record.total, 124750);
    expect(record.currency, 'RSD');
    expect(record.receipt.merchantName, 'Магнит');
    expect(columns.map((c) => c['name']), isNot(contains('grand_total')));
  });
}
