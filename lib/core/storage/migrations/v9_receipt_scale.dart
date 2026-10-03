import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../row.dart';
import 'legacy_eq.dart';
import 'migration.dart';

/// Money is scaled by the provider: receipts get a `scale` column, and stored
/// payloads written before `scale` existed get it filled in from their currency.
const v9ReceiptScale = Migration(version: 9, up: addReceiptScale);

Future<void> addReceiptScale(DatabaseExecutor db) async {
  if (!await tableExists(db, 'receipts')) return;
  if (!await columnExists(db, 'receipts', 'scale')) {
    await db.execute('ALTER TABLE receipts ADD COLUMN scale INTEGER NOT NULL DEFAULT 2');
  }
  for (final row in await db.query('receipts', columns: ['id', 'currency', 'payload'])) {
    final scale = legacyScale(row.str('currency'));
    Object? decoded;
    try {
      decoded = jsonDecode(row.str('payload'));
    } catch (_) {}
    final values = <String, Object?>{'scale': scale};
    if (decoded is Map && decoded['scale'] is int) {
      values['scale'] = decoded['scale'];
    } else if (decoded is Map) {
      values['payload'] = jsonEncode({...decoded, 'scale': scale});
    }
    await db.update('receipts', values, where: 'id = ?', whereArgs: [row['id']]);
  }
}
