import 'package:sqflite/sqflite.dart';

import 'migration.dart';

const v1Receipts = Migration(version: 1, up: createReceiptsTable);

Future<void> createReceiptsTable(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE receipts (
      id TEXT PRIMARY KEY,
      qr_hash TEXT NOT NULL UNIQUE,
      adapter_id TEXT NOT NULL,
      status TEXT NOT NULL,
      issued_at TEXT,
      merchant_name TEXT,
      grand_total REAL NOT NULL,
      currency TEXT NOT NULL,
      item_count INTEGER NOT NULL,
      payload TEXT NOT NULL,
      scanned_at TEXT NOT NULL,
      raw_qr TEXT NOT NULL
    )
  ''');
  await db.execute('CREATE UNIQUE INDEX idx_receipts_qr_hash ON receipts(qr_hash)');
}
