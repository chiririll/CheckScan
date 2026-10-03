import '../../storage/row.dart';
import '../model/catalog_product.dart';
import '../model/item_unit.dart';
import '../model/product_kind.dart';
import '../text/unit_parser.dart';
import 'catalog_tables.dart';
import 'tag_table.dart';

mixin ProductTable on CatalogTables, TagTable {
  Future<List<CatalogProduct>> listProducts() async {
    final rows = await (await db).query('product', orderBy: 'name ASC');
    final tags = await tagsByOwner(TagLink.product);
    return [
      for (final row in rows)
        CatalogProduct(
          id: row.str('id'),
          name: row.str('name'),
          categoryId: row.optStr('category_id'),
          unit: ItemUnit.tryParse(row.optStr('unit')),
          kind: ProductKind.parse(row.optStr('kind')),
          tags: tags[row.str('id')] ?? const [],
        ),
    ];
  }

  /// Without an explicit [unit], the unit is guessed from the name.
  Future<CatalogProduct> createProduct({
    required String name,
    String? categoryId,
    ItemUnit? unit,
    ProductKind kind = ProductKind.good,
  }) async {
    final trimmed = name.trim();
    final resolvedUnit = unit ?? parseItemUnit(trimmed)?.unit;
    final id = await (await db).insert('product', {
      'name': trimmed,
      'category_id': dbIdOrNull(categoryId),
      'unit': resolvedUnit?.name,
      'kind': kind.name,
    });
    return CatalogProduct(id: '$id', name: trimmed, categoryId: categoryId, unit: resolvedUnit, kind: kind);
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
    final values = <String, Object?>{
      'name': ?name?.trim(),
      if (clearCategory) 'category_id': null else if (categoryId != null) 'category_id': dbId(categoryId),
      if (clearUnit) 'unit': null else if (unit != null) 'unit': unit.name,
      'kind': ?kind?.name,
    };
    if (values.isEmpty) return;
    await (await db).update('product', values, where: 'id = ?', whereArgs: [dbId(id)]);
  }

  Future<void> deleteProduct(String id) async {
    final numeric = dbId(id);
    await (await db).transaction((txn) async {
      await txn.update('item', {'product_id': null}, where: 'product_id = ?', whereArgs: [numeric]);
      await txn.delete('product_tag', where: 'product_id = ?', whereArgs: [numeric]);
      await txn.delete('purchase', where: 'product_id = ?', whereArgs: [numeric]);
      await txn.delete('product', where: 'id = ?', whereArgs: [numeric]);
    });
  }
}
