import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../storage/database.dart';
import 'catalog_category.dart';
import 'catalog_position.dart';
import 'catalog_product.dart';
import 'catalog_resolver.dart';
import 'catalog_tag.dart';
import 'item_unit.dart';
import 'name_normalizer.dart';
import 'unit_parser.dart';

class CatalogRepository {
  CatalogRepository({required this.database});

  final CheckScanDatabase database;
  static const _uuid = Uuid();

  Future<Database> get _db => database.database;

  Future<List<CatalogCategory>> listCategories() async {
    final rows = await (await _db).query('categories', orderBy: 'sort_order ASC, name ASC');
    return [
      for (final row in rows)
        CatalogCategory(
          id: '${row['id']}',
          name: '${row['name']}',
          sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
          isSeed: (row['is_seed'] as num?)?.toInt() == 1,
        ),
    ];
  }

  Future<CatalogCategory> createCategory(String name) async {
    final db = await _db;
    final maxOrder = Sqflite.firstIntValue(await db.rawQuery('SELECT MAX(sort_order) FROM categories')) ?? -1;
    final category = CatalogCategory(id: _uuid.v4(), name: name.trim(), sortOrder: maxOrder + 1, isSeed: false);
    await db.insert('categories', {
      'id': category.id,
      'name': category.name,
      'sort_order': category.sortOrder,
      'is_seed': 0,
    });
    return category;
  }

  Future<void> renameCategory(String id, String name) async {
    await (await _db).update('categories', {'name': name.trim()}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCategory(String id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update('products', {'category_id': null}, where: 'category_id = ?', whereArgs: [id]);
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<CatalogProduct>> listProducts() async {
    final db = await _db;
    final productRows = await db.query('products', orderBy: 'name ASC');
    final tagRows = await db.rawQuery('''
      SELECT pt.product_id, t.id, t.name
      FROM product_tags pt
      JOIN tags t ON t.id = pt.tag_id
      ORDER BY t.name ASC
    ''');
    final tagsByProduct = <String, List<CatalogTag>>{};
    for (final row in tagRows) {
      final productId = '${row['product_id']}';
      tagsByProduct.putIfAbsent(productId, () => []).add(CatalogTag(id: '${row['id']}', name: '${row['name']}'));
    }
    return [
      for (final row in productRows)
        CatalogProduct(
          id: '${row['id']}',
          name: '${row['name']}',
          categoryId: row['category_id'] as String?,
          tags: tagsByProduct['${row['id']}'] ?? const [],
        ),
    ];
  }

  Future<CatalogProduct> createProduct({required String name, String? categoryId}) async {
    final product = CatalogProduct(id: _uuid.v4(), name: name.trim(), categoryId: categoryId);
    await (await _db).insert('products', {
      'id': product.id,
      'name': product.name,
      'category_id': product.categoryId,
    });
    return product;
  }

  Future<void> updateProduct(String id, {String? name, String? categoryId, bool clearCategory = false}) async {
    final values = <String, Object?>{};
    if (name != null) values['name'] = name.trim();
    if (clearCategory) {
      values['category_id'] = null;
    } else if (categoryId != null) {
      values['category_id'] = categoryId;
    }
    if (values.isEmpty) return;
    await (await _db).update('products', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteProduct(String id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update('positions', {'product_id': null}, where: 'product_id = ?', whereArgs: [id]);
      await txn.delete('product_tags', where: 'product_id = ?', whereArgs: [id]);
      await txn.delete('products', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<CatalogTag> addProductTag(String productId, String name) async {
    final db = await _db;
    final trimmed = name.trim();
    final key = tagNameKey(trimmed);
    return db.transaction((txn) async {
      final existing = await txn.query('tags', where: 'name_key = ?', whereArgs: [key], limit: 1);
      final tag = existing.isEmpty
          ? CatalogTag(id: _uuid.v4(), name: trimmed)
          : CatalogTag(id: '${existing.first['id']}', name: '${existing.first['name']}');
      if (existing.isEmpty) {
        await txn.insert('tags', {'id': tag.id, 'name': tag.name, 'name_key': key});
      }
      await txn.insert('product_tags', {
        'product_id': productId,
        'tag_id': tag.id,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return tag;
    });
  }

  Future<void> removeProductTag(String productId, String tagId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('product_tags', where: 'product_id = ? AND tag_id = ?', whereArgs: [productId, tagId]);
      final left = Sqflite.firstIntValue(
        await txn.rawQuery('SELECT COUNT(*) FROM product_tags WHERE tag_id = ?', [tagId]),
      );
      if (left == 0) {
        await txn.delete('tags', where: 'id = ?', whereArgs: [tagId]);
      }
    });
  }

  Future<List<CatalogPosition>> listPositions() async {
    final db = await _db;
    final positionRows = await db.query('positions', orderBy: 'display_name ASC');
    final aliasRows = await db.query('position_aliases');
    final aliases = <String, List<String>>{};
    for (final row in aliasRows) {
      aliases.putIfAbsent('${row['position_id']}', () => []).add('${row['raw_name']}');
    }
    return [
      for (final row in positionRows)
        CatalogPosition(
          id: '${row['id']}',
          displayName: '${row['display_name']}',
          productId: row['product_id'] as String?,
          unit: ItemUnit.tryParse(row['unit'] as String?),
          unitSize: (row['unit_size'] as num?)?.toDouble(),
          aliases: aliases['${row['id']}'] ?? const [],
        ),
    ];
  }

  Future<int> ingest(Iterable<String> descriptions) async {
    final db = await _db;
    var created = 0;
    await db.transaction((txn) async {
      for (final raw in descriptions) {
        if (raw.isEmpty) continue;
        final existing = await txn.query('position_aliases', where: 'raw_name = ?', whereArgs: [raw], limit: 1);
        if (existing.isNotEmpty) continue;
        final id = _uuid.v4();
        final parsed = parseItemUnit(raw);
        await txn.insert('positions', {
          'id': id,
          'display_name': raw,
          'product_id': null,
          'unit': parsed?.unit.name,
          'unit_size': parsed?.size,
        });
        await txn.insert('position_aliases', {
          'raw_name': raw,
          'normalized': normalizeItemName(raw),
          'position_id': id,
        });
        created += 1;
      }
    });
    return created;
  }

  Future<void> assignPosition(String positionId, String? productId) async {
    await (await _db).update('positions', {'product_id': productId}, where: 'id = ?', whereArgs: [positionId]);
  }

  Future<void> updatePosition(
    String id, {
    String? displayName,
    ItemUnit? unit,
    double? unitSize,
    bool clearUnit = false,
  }) async {
    final values = <String, Object?>{};
    if (displayName != null) values['display_name'] = displayName;
    if (clearUnit) {
      values['unit'] = null;
      values['unit_size'] = null;
    } else {
      if (unit != null) values['unit'] = unit.name;
      if (unitSize != null) values['unit_size'] = unitSize;
    }
    if (values.isEmpty) return;
    await (await _db).update('positions', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> mergePositions({required String sourceId, required String targetId}) async {
    if (sourceId == targetId) return;
    final db = await _db;
    await db.transaction((txn) async {
      final sourceRows = await txn.query('positions', where: 'id = ?', whereArgs: [sourceId], limit: 1);
      final targetRows = await txn.query('positions', where: 'id = ?', whereArgs: [targetId], limit: 1);
      if (sourceRows.isEmpty || targetRows.isEmpty) return;
      final source = sourceRows.first;
      final target = targetRows.first;
      if (target['unit'] == null && source['unit'] != null) {
        await txn.update('positions', {
          'unit': source['unit'],
          'unit_size': source['unit_size'],
        }, where: 'id = ?', whereArgs: [targetId]);
      }
      await txn.update('position_aliases', {'position_id': targetId}, where: 'position_id = ?', whereArgs: [sourceId]);
      await txn.delete('positions', where: 'id = ?', whereArgs: [sourceId]);
    });
  }

  Future<String?> unalias(String rawName) async {
    final db = await _db;
    return db.transaction((txn) async {
      final rows = await txn.query('position_aliases', where: 'raw_name = ?', whereArgs: [rawName], limit: 1);
      if (rows.isEmpty) return null;
      final oldId = '${rows.first['position_id']}';
      final siblings = Sqflite.firstIntValue(
        await txn.rawQuery('SELECT COUNT(*) FROM position_aliases WHERE position_id = ?', [oldId]),
      );
      if (siblings == 1) return oldId;
      final parsed = parseItemUnit(rawName);
      final id = _uuid.v4();
      await txn.insert('positions', {
        'id': id,
        'display_name': rawName,
        'product_id': null,
        'unit': parsed?.unit.name,
        'unit_size': parsed?.size,
      });
      await txn.update('position_aliases', {'position_id': id}, where: 'raw_name = ?', whereArgs: [rawName]);
      return id;
    });
  }

  Future<CatalogResolver> buildResolver() async {
    final categories = await listCategories();
    final products = await listProducts();
    final positions = await listPositions();
    final aliasRows = await (await _db).query('position_aliases');
    return CatalogResolver(
      byRawName: {for (final row in aliasRows) '${row['raw_name']}': '${row['position_id']}'},
      positions: {for (final position in positions) position.id: position},
      products: {for (final product in products) product.id: product},
      categories: {for (final category in categories) category.id: category},
    );
  }
}
