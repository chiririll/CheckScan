import 'package:sqflite/sqflite.dart';

import '../row.dart';
import 'migration.dart';

/// Dates are stored in UTC (`...Z`). Rows written before that carry local time without an offset;
/// those are read in the device's zone and rewritten as UTC.
const v10UtcDates = Migration(version: 10, up: normalizeDatesToUtc);

Future<void> normalizeDatesToUtc(DatabaseExecutor db) async {
  if (!await tableExists(db, 'receipts')) return;
  for (final row in await db.query('receipts', columns: ['id', 'issued_at', 'scanned_at'])) {
    final values = <String, Object?>{};
    for (final column in ['issued_at', 'scanned_at']) {
      final stored = row.optStr(column);
      final parsed = stored == null ? null : DateTime.tryParse(stored);
      if (parsed != null && !parsed.isUtc) values[column] = parsed.toUtc().toIso8601String();
    }
    if (values.isNotEmpty) await db.update('receipts', values, where: 'id = ?', whereArgs: [row['id']]);
  }
}
