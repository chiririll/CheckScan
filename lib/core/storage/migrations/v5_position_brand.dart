import 'package:sqflite/sqflite.dart';

import 'migration.dart';

const v5PositionBrand = Migration(version: 5, up: migratePositionBrand);

Future<void> migratePositionBrand(DatabaseExecutor db) async {
  if (!await tableExists(db, 'positions') || await columnExists(db, 'positions', 'brand')) return;
  await db.execute('ALTER TABLE positions ADD COLUMN brand TEXT');
}
