import 'package:sqflite/sqflite.dart';

import '../../catalog/category_seeder.dart';
import 'migration.dart';

final v6CatalogModel = Migration(version: 6, up: migrateToCatalogModel);

Future<void> migrateToCatalogModel(DatabaseExecutor db) async {
  if (await tableExists(db, 'category') && await tableExists(db, 'item')) {
    await _ensureSatellites(db);
    return;
  }
  final snapshot = await _readLegacy(db);
  await _dropLegacy(db);
  await createCatalogModelTables(db);
  await _copyLegacy(db, snapshot);
  await seedTwoLevelCategories(db);
  await _ensureSatellites(db);
}

Future<void> createCatalogModelTables(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE category (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      parent_id INTEGER REFERENCES category(id),
      sort_order INTEGER NOT NULL,
      icon TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE product (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category_id INTEGER REFERENCES category(id),
      unit TEXT,
      kind TEXT NOT NULL DEFAULT 'good'
    )
  ''');
  await db.execute('''
    CREATE TABLE item (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      product_id INTEGER REFERENCES product(id),
      unit_size REAL
    )
  ''');
  await db.execute('''
    CREATE TABLE tag (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE
    )
  ''');
  await db.execute('''
    CREATE TABLE product_tag (
      product_id INTEGER NOT NULL,
      tag_id INTEGER NOT NULL,
      PRIMARY KEY (product_id, tag_id)
    )
  ''');
  await db.execute('''
    CREATE TABLE item_tag (
      item_id INTEGER NOT NULL,
      tag_id INTEGER NOT NULL,
      PRIMARY KEY (item_id, tag_id)
    )
  ''');
  await db.execute('''
    CREATE TABLE item_alias (
      raw_name TEXT PRIMARY KEY,
      normalized TEXT NOT NULL,
      item_id INTEGER NOT NULL
    )
  ''');
  await db.execute('CREATE INDEX idx_item_alias_normalized ON item_alias(normalized)');
  await db.execute('CREATE INDEX idx_item_product ON item(product_id)');
}

Future<void> _ensureSatellites(DatabaseExecutor db) async {
  if (!await tableExists(db, 'merchant')) {
    await db.execute('''
      CREATE TABLE merchant (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER REFERENCES merchant(id),
        policy TEXT NOT NULL DEFAULT 'parse',
        category_id INTEGER REFERENCES category(id)
      )
    ''');
  }
  if (!await tableExists(db, 'merchant_alias')) {
    await db.execute('''
      CREATE TABLE merchant_alias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        tax_id TEXT,
        merchant_id INTEGER NOT NULL REFERENCES merchant(id)
      )
    ''');
  }
  if (!await tableExists(db, 'purchase')) {
    await db.execute('''
      CREATE TABLE purchase (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        check_id TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        UNIQUE (check_id, product_id)
      )
    ''');
  }
  if (await tableExists(db, 'receipts') && !await columnExists(db, 'receipts', 'merchant_id')) {
    await db.execute('ALTER TABLE receipts ADD COLUMN merchant_id INTEGER');
  }
}

class _LegacySnapshot {
  const _LegacySnapshot({
    required this.categories,
    required this.products,
    required this.tags,
    required this.productTags,
    required this.positions,
    required this.aliases,
  });

  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> products;
  final List<Map<String, Object?>> tags;
  final List<Map<String, Object?>> productTags;
  final List<Map<String, Object?>> positions;
  final List<Map<String, Object?>> aliases;
}

Future<_LegacySnapshot> _readLegacy(DatabaseExecutor db) async {
  Future<List<Map<String, Object?>>> rows(String table) async {
    if (!await tableExists(db, table)) return const [];
    return db.query(table);
  }

  return _LegacySnapshot(
    categories: await rows('categories'),
    products: await rows('products'),
    tags: await rows('tags'),
    productTags: await rows('product_tags'),
    positions: await rows('positions'),
    aliases: await rows('position_aliases'),
  );
}

Future<void> _dropLegacy(DatabaseExecutor db) async {
  for (final table in [
    'position_aliases',
    'positions',
    'product_tags',
    'tags',
    'products',
    'categories',
  ]) {
    await db.execute('DROP TABLE IF EXISTS $table');
  }
}

Future<void> _copyLegacy(DatabaseExecutor db, _LegacySnapshot snapshot) async {
  final categoryIds = <String, int>{};
  for (final row in snapshot.categories) {
    final id = await db.insert('category', {
      'name': row['name'],
      'parent_id': null,
      'sort_order': row['sort_order'] ?? 0,
      'icon': null,
    });
    categoryIds['${row['id']}'] = id;
  }

  final tagIds = <String, int>{};
  for (final row in snapshot.tags) {
    final id = await db.insert('tag', {'name': row['name']});
    tagIds['${row['id']}'] = id;
  }

  final productIds = <String, int>{};
  for (final row in snapshot.products) {
    final oldCategory = row['category_id'] as String?;
    final id = await db.insert('product', {
      'name': row['name'],
      'category_id': oldCategory == null ? null : categoryIds[oldCategory],
      'unit': row['unit'],
      'kind': 'good',
    });
    productIds['${row['id']}'] = id;
  }

  for (final row in snapshot.productTags) {
    final productId = productIds['${row['product_id']}'];
    final tagId = tagIds['${row['tag_id']}'];
    if (productId == null || tagId == null) continue;
    await db.insert('product_tag', {'product_id': productId, 'tag_id': tagId});
  }

  final itemIds = <String, int>{};
  for (final row in snapshot.positions) {
    final oldProduct = row['product_id'] as String?;
    final id = await db.insert('item', {
      'title': row['display_name'] ?? row['title'],
      'product_id': oldProduct == null ? null : productIds[oldProduct],
      'unit_size': row['unit_size'],
    });
    itemIds['${row['id']}'] = id;
  }

  for (final row in snapshot.aliases) {
    final itemId = itemIds['${row['position_id']}'];
    if (itemId == null) continue;
    await db.insert('item_alias', {
      'raw_name': row['raw_name'],
      'normalized': row['normalized'],
      'item_id': itemId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
