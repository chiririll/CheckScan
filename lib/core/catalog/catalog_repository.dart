import 'package:sqflite/sqflite.dart';

import '../merchant/merchant.dart';
import '../models/receipt_record.dart';
import '../storage/database.dart';
import 'catalog_category.dart';
import 'catalog_position.dart';
import 'catalog_product.dart';
import 'catalog_resolver.dart';
import 'catalog_tag.dart';
import 'item_unit.dart';
import 'name_normalizer.dart';
import 'product_kind.dart';
import 'purchase_cache.dart';
import 'unit_parser.dart';

class CatalogRepository {
  CatalogRepository({required this.database});

  final CheckScanDatabase database;

  Future<Database> get _db => database.database;

  Future<List<CatalogCategory>> listCategories() async {
    final rows = await (await _db).query('category', orderBy: 'sort_order ASC, name ASC');
    return [
      for (final row in rows)
        CatalogCategory(
          id: '${row['id']}',
          name: '${row['name']}',
          parentId: row['parent_id'] == null ? null : '${row['parent_id']}',
          sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
          icon: row['icon'] as String?,
        ),
    ];
  }

  Future<CatalogCategory> createCategory(String name, {String? parentId}) async {
    final db = await _db;
    final parent = parentId == null ? null : int.parse(parentId);
    if (parent != null) {
      final rows = await db.query('category', where: 'id = ?', whereArgs: [parent], limit: 1);
      if (rows.isEmpty || rows.first['parent_id'] != null) {
        throw StateError('category parent must be a top-level shelf');
      }
    }
    final maxOrder = Sqflite.firstIntValue(await db.rawQuery('SELECT MAX(sort_order) FROM category')) ?? -1;
    final id = await db.insert('category', {
      'name': name.trim(),
      'parent_id': parent,
      'sort_order': maxOrder + 1,
      'icon': null,
    });
    return CatalogCategory(id: '$id', name: name.trim(), parentId: parentId, sortOrder: maxOrder + 1);
  }

  Future<void> renameCategory(String id, String name) async {
    await (await _db).update('category', {'name': name.trim()}, where: 'id = ?', whereArgs: [int.parse(id)]);
  }

  Future<void> deleteCategory(String id) async {
    final db = await _db;
    final numeric = int.parse(id);
    await db.transaction((txn) async {
      final childRows = await txn.query('category', where: 'parent_id = ?', whereArgs: [numeric]);
      final ids = [numeric, for (final row in childRows) (row['id'] as num).toInt()];
      for (final categoryId in ids) {
        await txn.update('product', {'category_id': null}, where: 'category_id = ?', whereArgs: [categoryId]);
        await txn.update('merchant', {'category_id': null}, where: 'category_id = ?', whereArgs: [categoryId]);
      }
      for (final child in childRows) {
        await txn.delete('category', where: 'id = ?', whereArgs: [child['id']]);
      }
      await txn.delete('category', where: 'id = ?', whereArgs: [numeric]);
    });
  }

  Future<List<CatalogProduct>> listProducts() async {
    final db = await _db;
    final productRows = await db.query('product', orderBy: 'name ASC');
    final tagRows = await db.rawQuery('''
      SELECT pt.product_id, t.id, t.name
      FROM product_tag pt
      JOIN tag t ON t.id = pt.tag_id
      ORDER BY t.name ASC
    ''');
    final tagsByProduct = <String, List<CatalogTag>>{};
    for (final row in tagRows) {
      tagsByProduct.putIfAbsent('${row['product_id']}', () => []).add(CatalogTag(id: '${row['id']}', name: '${row['name']}'));
    }
    return [
      for (final row in productRows)
        CatalogProduct(
          id: '${row['id']}',
          name: '${row['name']}',
          categoryId: row['category_id'] == null ? null : '${row['category_id']}',
          unit: ItemUnit.tryParse(row['unit'] as String?),
          kind: ProductKind.parse(row['kind'] as String?),
          tags: tagsByProduct['${row['id']}'] ?? const [],
        ),
    ];
  }

  Future<CatalogProduct> createProduct({
    required String name,
    String? categoryId,
    ItemUnit? unit,
    ProductKind kind = ProductKind.good,
  }) async {
    final trimmed = name.trim();
    final id = await (await _db).insert('product', {
      'name': trimmed,
      'category_id': categoryId == null ? null : int.parse(categoryId),
      'unit': (unit ?? parseItemUnit(trimmed)?.unit)?.name,
      'kind': kind.name,
    });
    return CatalogProduct(
      id: '$id',
      name: trimmed,
      categoryId: categoryId,
      unit: unit ?? parseItemUnit(trimmed)?.unit,
      kind: kind,
    );
  }

  Future<void> updateProduct(
    String id, {
    String? name,
    String? categoryId,
    bool clearCategory = false,
    ItemUnit? unit,
    bool clearUnit = false,
    ProductKind? kind,
  }) async {
    final values = <String, Object?>{};
    if (name != null) values['name'] = name.trim();
    if (clearCategory) {
      values['category_id'] = null;
    } else if (categoryId != null) {
      values['category_id'] = int.parse(categoryId);
    }
    if (clearUnit) {
      values['unit'] = null;
    } else if (unit != null) {
      values['unit'] = unit.name;
    }
    if (kind != null) values['kind'] = kind.name;
    if (values.isEmpty) return;
    await (await _db).update('product', values, where: 'id = ?', whereArgs: [int.parse(id)]);
  }

  Future<void> deleteProduct(String id) async {
    final db = await _db;
    final numeric = int.parse(id);
    await db.transaction((txn) async {
      await txn.update('item', {'product_id': null}, where: 'product_id = ?', whereArgs: [numeric]);
      await txn.delete('product_tag', where: 'product_id = ?', whereArgs: [numeric]);
      await txn.delete('purchase', where: 'product_id = ?', whereArgs: [numeric]);
      await txn.delete('product', where: 'id = ?', whereArgs: [numeric]);
    });
  }

  Future<CatalogTag> addProductTag(String productId, String name) async {
    return _addTag(ownerColumn: 'product_id', ownerId: productId, table: 'product_tag', name: name);
  }

  Future<void> removeProductTag(String productId, String tagId) async {
    await _removeTag(ownerColumn: 'product_id', ownerId: productId, table: 'product_tag', tagId: tagId);
  }

  Future<CatalogTag> addItemTag(String itemId, String name) async {
    return _addTag(ownerColumn: 'item_id', ownerId: itemId, table: 'item_tag', name: name);
  }

  Future<void> removeItemTag(String itemId, String tagId) async {
    await _removeTag(ownerColumn: 'item_id', ownerId: itemId, table: 'item_tag', tagId: tagId);
  }

  Future<CatalogTag> _addTag({
    required String ownerColumn,
    required String ownerId,
    required String table,
    required String name,
  }) async {
    final db = await _db;
    final trimmed = name.trim();
    final key = tagNameKey(trimmed);
    return db.transaction((txn) async {
      final existing = await txn.query('tag');
      Map<String, Object?>? hit;
      for (final row in existing) {
        if (tagNameKey('${row['name']}') == key) {
          hit = row;
          break;
        }
      }
      final tag = hit == null
          ? CatalogTag(id: '${await txn.insert('tag', {'name': trimmed})}', name: trimmed)
          : CatalogTag(id: '${hit['id']}', name: '${hit['name']}');
      await txn.insert(table, {
        ownerColumn: int.parse(ownerId),
        'tag_id': int.parse(tag.id),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return tag;
    });
  }

  Future<void> _removeTag({
    required String ownerColumn,
    required String ownerId,
    required String table,
    required String tagId,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(table, where: '$ownerColumn = ? AND tag_id = ?', whereArgs: [int.parse(ownerId), int.parse(tagId)]);
      final left = (Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM product_tag WHERE tag_id = ?', [int.parse(tagId)])) ?? 0) +
          (Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM item_tag WHERE tag_id = ?', [int.parse(tagId)])) ?? 0);
      if (left == 0) {
        await txn.delete('tag', where: 'id = ?', whereArgs: [int.parse(tagId)]);
      }
    });
  }

  Future<List<CatalogPosition>> listPositions() async {
    final db = await _db;
    final itemRows = await db.query('item', orderBy: 'title ASC');
    final aliasRows = await db.query('item_alias');
    final tagRows = await db.rawQuery('''
      SELECT it.item_id, t.id, t.name
      FROM item_tag it
      JOIN tag t ON t.id = it.tag_id
      ORDER BY t.name ASC
    ''');
    final aliases = <String, List<String>>{};
    for (final row in aliasRows) {
      aliases.putIfAbsent('${row['item_id']}', () => []).add('${row['raw_name']}');
    }
    final tags = <String, List<CatalogTag>>{};
    for (final row in tagRows) {
      tags.putIfAbsent('${row['item_id']}', () => []).add(CatalogTag(id: '${row['id']}', name: '${row['name']}'));
    }
    return [
      for (final row in itemRows)
        CatalogPosition(
          id: '${row['id']}',
          displayName: '${row['title']}',
          productId: row['product_id'] == null ? null : '${row['product_id']}',
          unitSize: (row['unit_size'] as num?)?.toDouble(),
          aliases: aliases['${row['id']}'] ?? const [],
          tags: tags['${row['id']}'] ?? const [],
        ),
    ];
  }

  Future<int> ingest(Iterable<String> descriptions) async {
    final db = await _db;
    var created = 0;
    await db.transaction((txn) async {
      for (final raw in descriptions) {
        if (raw.isEmpty) continue;
        final existing = await txn.query('item_alias', where: 'raw_name = ?', whereArgs: [raw], limit: 1);
        if (existing.isNotEmpty) continue;
        final parsed = parseItemUnit(raw);
        final id = await txn.insert('item', {
          'title': raw,
          'product_id': null,
          'unit_size': parsed?.size,
        });
        await txn.insert('item_alias', {
          'raw_name': raw,
          'normalized': normalizeItemName(raw),
          'item_id': id,
        });
        created += 1;
      }
    });
    return created;
  }

  Future<int> ingestFromReceipts(List<ReceiptRecord> receipts, Iterable<Merchant> merchants) async {
    final ignored = ignoreMerchantIdsOf(merchants);
    final names = <String>{};
    for (final receipt in receipts) {
      if (receipt.merchantId != null && ignored.contains(receipt.merchantId)) continue;
      for (final item in receipt.receipt.items) {
        if (item.description.isNotEmpty) names.add(item.description);
      }
    }
    return ingest(names);
  }

  Future<void> assignPosition(String positionId, String? productId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        'item',
        {'product_id': productId == null ? null : int.parse(productId)},
        where: 'id = ?',
        whereArgs: [int.parse(positionId)],
      );
      if (productId == null) return;
      final productRows = await txn.query('product', where: 'id = ?', whereArgs: [int.parse(productId)], limit: 1);
      if (productRows.isEmpty || productRows.first['unit'] != null) return;
      final itemRows = await txn.query('item', where: 'id = ?', whereArgs: [int.parse(positionId)], limit: 1);
      if (itemRows.isEmpty) return;
      final parsed = parseItemUnit('${itemRows.first['title']}');
      if (parsed?.unit == null) return;
      await txn.update('product', {'unit': parsed!.unit.name}, where: 'id = ?', whereArgs: [int.parse(productId)]);
    });
  }

  Future<void> updatePosition(String id, {double? unitSize, bool clearAmount = false}) async {
    final values = <String, Object?>{};
    if (clearAmount) {
      values['unit_size'] = null;
    } else if (unitSize != null) {
      values['unit_size'] = unitSize;
    }
    if (values.isEmpty) return;
    await (await _db).update('item', values, where: 'id = ?', whereArgs: [int.parse(id)]);
  }

  Future<void> mergePositions({required String sourceId, required String targetId}) async {
    if (sourceId == targetId) return;
    final db = await _db;
    await db.transaction((txn) async {
      final sourceRows = await txn.query('item', where: 'id = ?', whereArgs: [int.parse(sourceId)], limit: 1);
      final targetRows = await txn.query('item', where: 'id = ?', whereArgs: [int.parse(targetId)], limit: 1);
      if (sourceRows.isEmpty || targetRows.isEmpty) return;
      if (targetRows.first['unit_size'] == null && sourceRows.first['unit_size'] != null) {
        await txn.update('item', {'unit_size': sourceRows.first['unit_size']}, where: 'id = ?', whereArgs: [int.parse(targetId)]);
      }
      await txn.update('item_alias', {'item_id': int.parse(targetId)}, where: 'item_id = ?', whereArgs: [int.parse(sourceId)]);
      await txn.update('item_tag', {'item_id': int.parse(targetId)}, where: 'item_id = ?', whereArgs: [int.parse(sourceId)], conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.delete('item_tag', where: 'item_id = ?', whereArgs: [int.parse(sourceId)]);
      await txn.delete('item', where: 'id = ?', whereArgs: [int.parse(sourceId)]);
    });
  }

  Future<String?> unalias(String rawName) async {
    final db = await _db;
    return db.transaction((txn) async {
      final rows = await txn.query('item_alias', where: 'raw_name = ?', whereArgs: [rawName], limit: 1);
      if (rows.isEmpty) return null;
      final oldId = (rows.first['item_id'] as num).toInt();
      final siblings = Sqflite.firstIntValue(
        await txn.rawQuery('SELECT COUNT(*) FROM item_alias WHERE item_id = ?', [oldId]),
      );
      if (siblings == 1) return '$oldId';
      final parsed = parseItemUnit(rawName);
      final id = await txn.insert('item', {
        'title': rawName,
        'product_id': null,
        'unit_size': parsed?.size,
      });
      await txn.update('item_alias', {'item_id': id}, where: 'raw_name = ?', whereArgs: [rawName]);
      return '$id';
    });
  }

  Future<CatalogResolver> buildResolver() async {
    final categories = await listCategories();
    final products = await listProducts();
    final positions = await listPositions();
    final aliasRows = await (await _db).query('item_alias');
    return CatalogResolver(
      byRawName: {for (final row in aliasRows) '${row['raw_name']}': '${row['item_id']}'},
      positions: {for (final position in positions) position.id: position},
      products: {for (final product in products) product.id: product},
      categories: {for (final category in categories) category.id: category},
    );
  }

  Future<void> rebuildPurchases({
    required List<ReceiptRecord> receipts,
    required Iterable<Merchant> merchants,
  }) async {
    await rebuildPurchaseCache(
      db: await _db,
      receipts: receipts,
      resolver: await buildResolver(),
      ignoreMerchantIds: ignoreMerchantIdsOf(merchants),
    );
  }
}
