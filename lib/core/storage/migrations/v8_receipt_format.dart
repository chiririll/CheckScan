import 'dart:convert';

import 'package:receipt_model/receipt_model.dart';
import 'package:sqflite/sqflite.dart';

import '../row.dart';
import 'legacy_eq.dart';
import 'migration.dart';

/// Money becomes integer minor units: `grand_total REAL` → `total INTEGER`,
/// and stored eQ payloads are rewritten in the CheckScan receipt format.
const v8ReceiptFormat = Migration(version: 8, up: migrateReceiptFormat);

Future<void> migrateReceiptFormat(DatabaseExecutor db) async {
  if (!await tableExists(db, 'receipts') || await columnExists(db, 'receipts', 'total')) return;
  await db.execute('''
    CREATE TABLE receipts_v8 (
      id TEXT PRIMARY KEY,
      qr_hash TEXT NOT NULL UNIQUE,
      adapter_id TEXT NOT NULL,
      status TEXT NOT NULL,
      issued_at TEXT,
      merchant_name TEXT,
      total INTEGER NOT NULL,
      currency TEXT NOT NULL,
      item_count INTEGER NOT NULL,
      payload TEXT NOT NULL,
      scanned_at TEXT NOT NULL,
      raw_qr TEXT NOT NULL,
      last_status INTEGER NOT NULL DEFAULT 200,
      merchant_id INTEGER
    )
  ''');
  final hasLastStatus = await columnExists(db, 'receipts', 'last_status');
  final hasMerchant = await columnExists(db, 'receipts', 'merchant_id');
  for (final row in await db.query('receipts')) {
    final receipt = _convert(row);
    await db.insert('receipts_v8', {
      'id': row['id'],
      'qr_hash': row['qr_hash'],
      'adapter_id': row['adapter_id'],
      'status': row['status'],
      'issued_at': row['issued_at'],
      'merchant_name': row['merchant_name'],
      'total': receipt.total,
      'currency': row['currency'],
      'item_count': row['item_count'],
      'payload': receipt.encode(),
      'scanned_at': row['scanned_at'],
      'raw_qr': row['raw_qr'],
      'last_status': hasLastStatus ? row['last_status'] ?? 200 : 200,
      'merchant_id': hasMerchant ? row['merchant_id'] : null,
    });
  }
  await db.execute('DROP TABLE receipts');
  await db.execute('ALTER TABLE receipts_v8 RENAME TO receipts');
  await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_receipts_qr_hash ON receipts(qr_hash)');
}

Receipt _convert(Map<String, Object?> row) {
  final payload = row.str('payload');
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map) {
      final json = Map<String, dynamic>.from(decoded);
      // A payload already in the CheckScan format may predate `scale`.
      return Receipt.isReceiptJson(json) ? Receipt.fromJson({'scale': legacyScale('${json['currency']}'), ...json}) : receiptFromEq(json);
    }
  } catch (_) {}
  // Unreadable payload: keep what the columns know.
  final currency = row.str('currency').isEmpty ? 'RUB' : row.str('currency');
  return Receipt(
    id: row.str('id'),
    issuedAt: row.date('issued_at') ?? row.date('scanned_at') ?? DateTime.now(),
    currency: currency,
    scale: legacyScale(currency),
    total: legacyMinor(row['grand_total'], legacyScale(currency)),
    merchantName: row.optStr('merchant_name'),
  );
}
