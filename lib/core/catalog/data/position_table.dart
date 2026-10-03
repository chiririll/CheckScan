import 'package:sqflite/sqflite.dart';

import '../../storage/row.dart';
import '../model/catalog_position.dart';
import '../text/name_normalizer.dart';
import '../text/unit_parser.dart';
import 'catalog_tables.dart';
import 'tag_table.dart';

/// Positions live in `item`; every raw cashier name is an `item_alias` row.
mixin PositionTable on CatalogTables, TagTable {
  Future<List<CatalogPosition>> listPositions() async {
    final database = await db;
    final itemRows = await database.query('item', orderBy: 'title ASC');
    final aliasRows = await database.query('item_alias');
    final tags = await tagsByOwner(TagLink.item);
    final aliases = <String, List<String>>{};
    for (final row in aliasRows) {
      aliases.putIfAbsent(row.str('item_id'), () => []).add(row.str('raw_name'));
    }
    return [
      for (final row in itemRows)
        CatalogPosition(
          id: row.str('id'),
          displayName: row.str('title'),
          productId: row.optStr('product_id'),
          unitSize: row.optDouble('unit_size'),
          aliases: aliases[row.str('id')] ?? const [],
          tags: tags[row.str('id')] ?? const [],
        ),
    ];
  }

  /// Creates one position per unseen raw name. Returns how many were created.
  Future<int> ingest(Iterable<String> descriptions) async {
    var created = 0;
    await (await db).transaction((txn) async {
      final known = {for (final row in await txn.query('item_alias', columns: ['raw_name'])) row.str('raw_name')};
      for (final raw in descriptions) {
        if (raw.isEmpty || !known.add(raw)) continue;
        final id = await _insertItem(txn, raw);
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

  /// Links a position to a product; a unitless product inherits the position's unit.
  Future<void> assignPosition(String positionId, String? productId) async {
    final position = dbId(positionId);
    await (await db).transaction((txn) async {
      await txn.update('item', {'product_id': dbIdOrNull(productId)}, where: 'id = ?', whereArgs: [position]);
      if (productId == null) return;
      final product = dbId(productId);
      final productRows = await txn.query('product', where: 'id = ?', whereArgs: [product], limit: 1);
      if (productRows.isEmpty || productRows.first['unit'] != null) return;
      final itemRows = await txn.query('item', where: 'id = ?', whereArgs: [position], limit: 1);
      if (itemRows.isEmpty) return;
      final unit = parseItemUnit(itemRows.first.str('title'))?.unit;
      if (unit == null) return;
      await txn.update('product', {'unit': unit.name}, where: 'id = ?', whereArgs: [product]);
    });
  }

  Future<void> updatePosition(String id, {double? unitSize, bool clearAmount = false}) async {
    if (!clearAmount && unitSize == null) return;
    await (await db).update('item', {'unit_size': clearAmount ? null : unitSize}, where: 'id = ?', whereArgs: [dbId(id)]);
  }

  /// Moves aliases and tags of [sourceId] into [targetId] and drops the source.
  Future<void> mergePositions({required String sourceId, required String targetId}) async {
    if (sourceId == targetId) return;
    final source = dbId(sourceId);
    final target = dbId(targetId);
    await (await db).transaction((txn) async {
      final sourceRows = await txn.query('item', where: 'id = ?', whereArgs: [source], limit: 1);
      final targetRows = await txn.query('item', where: 'id = ?', whereArgs: [target], limit: 1);
      if (sourceRows.isEmpty || targetRows.isEmpty) return;
      if (targetRows.first['unit_size'] == null && sourceRows.first['unit_size'] != null) {
        await txn.update('item', {'unit_size': sourceRows.first['unit_size']}, where: 'id = ?', whereArgs: [target]);
      }
      await txn.update('item_alias', {'item_id': target}, where: 'item_id = ?', whereArgs: [source]);
      await txn.update('item_tag', {'item_id': target},
          where: 'item_id = ?', whereArgs: [source], conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.delete('item_tag', where: 'item_id = ?', whereArgs: [source]);
      await txn.delete('item', where: 'id = ?', whereArgs: [source]);
    });
  }

  /// Splits [rawName] into its own position. A sole alias keeps its position.
  Future<String?> unalias(String rawName) async {
    return (await db).transaction((txn) async {
      final rows = await txn.query('item_alias', where: 'raw_name = ?', whereArgs: [rawName], limit: 1);
      if (rows.isEmpty) return null;
      final oldId = rows.first.optInt('item_id')!;
      final siblings = Sqflite.firstIntValue(
        await txn.rawQuery('SELECT COUNT(*) FROM item_alias WHERE item_id = ?', [oldId]),
      );
      if (siblings == 1) return '$oldId';
      final id = await _insertItem(txn, rawName);
      await txn.update('item_alias', {'item_id': id}, where: 'raw_name = ?', whereArgs: [rawName]);
      return '$id';
    });
  }

  Future<int> _insertItem(DatabaseExecutor txn, String raw) {
    return txn.insert('item', {
      'title': raw,
      'product_id': null,
      'unit_size': parseItemUnit(raw)?.size,
    });
  }
}
