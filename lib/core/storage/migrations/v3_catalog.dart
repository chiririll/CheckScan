import 'package:sqflite/sqflite.dart';

import '../../catalog/category_seeder.dart';
import 'migration.dart';

final v3Catalog = Migration(
  version: 3,
  up: (db) async {
    if (await tableExists(db, 'categories') || await tableExists(db, 'category')) return;
    await createCatalogTables(db);
    await seedCategoriesIfEmpty(db);
  },
);

Future<void> createCatalogTables(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      sort_order INTEGER NOT NULL,
      is_seed INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE tags (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      name_key TEXT NOT NULL UNIQUE
    )
  ''');
  await db.execute('''
    CREATE TABLE products (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      category_id TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE product_tags (
      product_id TEXT NOT NULL,
      tag_id TEXT NOT NULL,
      PRIMARY KEY (product_id, tag_id)
    )
  ''');
  await db.execute('''
    CREATE TABLE positions (
      id TEXT PRIMARY KEY,
      display_name TEXT NOT NULL,
      product_id TEXT,
      unit_size REAL
    )
  ''');
  await db.execute('''
    CREATE TABLE position_aliases (
      raw_name TEXT PRIMARY KEY,
      normalized TEXT NOT NULL,
      position_id TEXT NOT NULL
    )
  ''');
  await db.execute('CREATE INDEX idx_position_aliases_normalized ON position_aliases(normalized)');
  await db.execute('CREATE INDEX idx_positions_product ON positions(product_id)');
}
