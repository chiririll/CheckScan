import 'package:sqflite/sqflite.dart';

import '../../storage/row.dart';
import '../model/suggestion_ignore.dart';
import 'catalog_tables.dart';

mixin SuggestionIgnoreTable on CatalogTables {
  Future<SuggestionIgnore> listSuggestionIgnores() async {
    final database = await db;
    final clusterRows = await database.query('cluster_ignore');
    final productRows = await database.query('product_suggestion_ignore');
    return SuggestionIgnore(
      clusterItemIds: {for (final row in clusterRows) row.str('item_id')},
      productItemKeys: {
        for (final row in productRows) SuggestionIgnore.productKey(row.str('product_id'), row.str('item_id')),
      },
    );
  }

  Future<void> ignoreClusterItem(String itemId) => ignoreClusterItems([itemId]);

  Future<void> ignoreClusterItems(Iterable<String> itemIds) async {
    final batch = (await db).batch();
    for (final itemId in itemIds) {
      batch.insert('cluster_ignore', {'item_id': dbId(itemId)}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> ignoreProductSuggestion({required String productId, required String itemId}) async {
    await (await db).insert(
      'product_suggestion_ignore',
      {'product_id': dbId(productId), 'item_id': dbId(itemId)},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
