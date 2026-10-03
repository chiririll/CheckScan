import 'package:sqflite/sqflite.dart';

import 'migration.dart';

const v4ProductUnits = Migration(version: 4, up: migrateCatalogUnitsToProducts);

Future<void> migrateCatalogUnitsToProducts(DatabaseExecutor db) async {
  if (!await tableExists(db, 'products') || await columnExists(db, 'products', 'unit')) return;
  await db.execute('ALTER TABLE products ADD COLUMN unit TEXT');
  if (!await tableExists(db, 'positions') || !await columnExists(db, 'positions', 'unit')) return;
  await db.execute('''
    UPDATE products
    SET unit = (
      SELECT p.unit FROM positions p
      WHERE p.product_id = products.id AND p.unit IS NOT NULL
      LIMIT 1
    )
    WHERE unit IS NULL
  ''');
}
