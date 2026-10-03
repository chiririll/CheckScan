import '../../merchant/merchant.dart';
import '../../models/receipt_record.dart';
import '../catalog_resolver.dart';
import 'catalog_tables.dart';
import 'category_table.dart';
import 'position_table.dart';
import 'product_table.dart';
import 'purchase_table.dart';
import 'suggestion_ignore_table.dart';
import 'tag_table.dart';

/// Catalog persistence. Each table's queries live in its own mixin.
class CatalogRepository extends CatalogTables
    with CategoryTable, TagTable, ProductTable, PositionTable, SuggestionIgnoreTable, PurchaseTable {
  CatalogRepository({required super.database});

  /// Ingests every item name of receipts whose merchant still parses items.
  Future<int> ingestFromReceipts(List<ReceiptRecord> receipts, Iterable<Merchant> merchants) {
    final ignored = ignoreMerchantIdsOf(merchants);
    return ingest({
      for (final receipt in receipts)
        if (!ignored.contains(receipt.merchantId))
          for (final item in receipt.receipt.items)
            if (item.description.isNotEmpty) item.description,
    });
  }

  Future<CatalogResolver> buildResolver() async {
    return CatalogResolver.from(
      categories: await listCategories(),
      products: await listProducts(),
      positions: await listPositions(),
    );
  }

  Future<void> rebuildPurchases({
    required List<ReceiptRecord> receipts,
    required Iterable<Merchant> merchants,
    CatalogResolver? resolver,
  }) async {
    await writePurchases(
      receipts: receipts,
      resolver: resolver ?? await buildResolver(),
      ignoreMerchantIds: ignoreMerchantIdsOf(merchants),
    );
  }
}
