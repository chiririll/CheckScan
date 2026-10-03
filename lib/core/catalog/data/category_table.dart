import 'package:sqflite/sqflite.dart';

import '../../storage/row.dart';
import '../model/catalog_category.dart';
import 'catalog_tables.dart';

mixin CategoryTable on CatalogTables {
  Future<List<CatalogCategory>> listCategories() async {
    final rows = await (await db).query('category', orderBy: 'sort_order ASC, name ASC');
    return [
      for (final row in rows)
        CatalogCategory(
          id: row.str('id'),
          name: row.str('name'),
          parentId: row.optStr('parent_id'),
          sortOrder: row.optInt('sort_order') ?? 0,
          icon: row.optStr('icon'),
        ),
    ];
  }

  Future<CatalogCategory> createCategory(String name, {String? parentId}) async {
    final database = await db;
    final parent = dbIdOrNull(parentId);
    if (parent != null) {
      final rows = await database.query('category', where: 'id = ?', whereArgs: [parent], limit: 1);
      if (rows.isEmpty || rows.first['parent_id'] != null) {
        throw StateError('category parent must be a top-level shelf');
      }
    }
    final sortOrder = (Sqflite.firstIntValue(await database.rawQuery('SELECT MAX(sort_order) FROM category')) ?? -1) + 1;
    final trimmed = name.trim();
    final id = await database.insert('category', {
      'name': trimmed,
      'parent_id': parent,
      'sort_order': sortOrder,
      'icon': null,
    });
    return CatalogCategory(id: '$id', name: trimmed, parentId: parentId, sortOrder: sortOrder);
  }

  Future<void> renameCategory(String id, String name) async {
    await (await db).update('category', {'name': name.trim()}, where: 'id = ?', whereArgs: [dbId(id)]);
  }

  /// Deletes the category and its children; products and merchants lose the link.
  Future<void> deleteCategory(String id) async {
    final numeric = dbId(id);
    await (await db).transaction((txn) async {
      final childRows = await txn.query('category', where: 'parent_id = ?', whereArgs: [numeric]);
      final ids = [for (final row in childRows) row.optInt('id')!, numeric];
      for (final categoryId in ids) {
        await txn.update('product', {'category_id': null}, where: 'category_id = ?', whereArgs: [categoryId]);
        await txn.update('merchant', {'category_id': null}, where: 'category_id = ?', whereArgs: [categoryId]);
        await txn.delete('category', where: 'id = ?', whereArgs: [categoryId]);
      }
    });
  }
}
