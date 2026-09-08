import 'migration.dart';

final v2LastStatus = Migration(
  version: 2,
  up: (db) async {
    if (await columnExists(db, 'receipts', 'last_status')) return;
    await db.execute('ALTER TABLE receipts ADD COLUMN last_status INTEGER NOT NULL DEFAULT 200');
  },
);
