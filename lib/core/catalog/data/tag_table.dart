import 'package:sqflite/sqflite.dart';

import '../../storage/row.dart';
import '../model/catalog_tag.dart';
import '../text/name_normalizer.dart';
import 'catalog_tables.dart';

/// Link table between a tag and its owner (product or item).
enum TagLink {
  product('product_tag', 'product_id'),
  item('item_tag', 'item_id');

  const TagLink(this.table, this.ownerColumn);

  final String table;
  final String ownerColumn;
}

mixin TagTable on CatalogTables {
  Future<CatalogTag> addProductTag(String productId, String name) => addTag(TagLink.product, productId, name);

  Future<void> removeProductTag(String productId, String tagId) => removeTag(TagLink.product, productId, tagId);

  Future<CatalogTag> addItemTag(String itemId, String name) => addTag(TagLink.item, itemId, name);

  Future<void> removeItemTag(String itemId, String tagId) => removeTag(TagLink.item, itemId, tagId);

  /// Tags are shared by case-insensitive name.
  Future<CatalogTag> addTag(TagLink link, String ownerId, String name) async {
    final trimmed = name.trim();
    final key = tagNameKey(trimmed);
    return (await db).transaction((txn) async {
      final existing = await txn.query('tag');
      final hit = existing.where((row) => tagNameKey(row.str('name')) == key).firstOrNull;
      final tag = hit == null
          ? CatalogTag(id: '${await txn.insert('tag', {'name': trimmed})}', name: trimmed)
          : CatalogTag(id: hit.str('id'), name: hit.str('name'));
      await txn.insert(link.table, {
        link.ownerColumn: dbId(ownerId),
        'tag_id': dbId(tag.id),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return tag;
    });
  }

  /// Unlinks the tag and drops it once nothing references it.
  Future<void> removeTag(TagLink link, String ownerId, String tagId) async {
    final tag = dbId(tagId);
    await (await db).transaction((txn) async {
      await txn.delete(link.table, where: '${link.ownerColumn} = ? AND tag_id = ?', whereArgs: [dbId(ownerId), tag]);
      var left = 0;
      for (final other in TagLink.values) {
        left += Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM ${other.table} WHERE tag_id = ?', [tag])) ?? 0;
      }
      if (left == 0) await txn.delete('tag', where: 'id = ?', whereArgs: [tag]);
    });
  }

  /// Owner id → its tags, sorted by name.
  Future<Map<String, List<CatalogTag>>> tagsByOwner(TagLink link) async {
    final rows = await (await db).rawQuery('''
      SELECT l.${link.ownerColumn} AS owner_id, t.id, t.name
      FROM ${link.table} l
      JOIN tag t ON t.id = l.tag_id
      ORDER BY t.name ASC
    ''');
    final tags = <String, List<CatalogTag>>{};
    for (final row in rows) {
      tags.putIfAbsent(row.str('owner_id'), () => []).add(CatalogTag(id: row.str('id'), name: row.str('name')));
    }
    return tags;
  }
}
