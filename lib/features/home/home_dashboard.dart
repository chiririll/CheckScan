import '../../core/catalog/catalog_resolver.dart';
import '../../core/catalog/model/catalog_category.dart';
import '../../core/catalog/model/catalog_position.dart';
import '../../core/catalog/model/catalog_product.dart';
import '../../core/catalog/model/purchase.dart';
import '../../core/catalog/pricing/price_point.dart';
import '../../core/catalog/purchase_stats.dart';
import '../../core/merchant/merchant.dart';
import '../../core/models/receipt_record.dart';
import '../../core/util/collections.dart';
import 'dashboard/price_rows.dart';
import 'dashboard/waste.dart';
import 'home_period.dart';

export 'dashboard/price_rows.dart';
export 'dashboard/waste.dart';

class FrequentItem {
  const FrequentItem({
    required this.productId,
    required this.name,
    required this.count,
    required this.quantity,
  });

  final String productId;
  final String name;
  final int count;
  final double quantity;
}

class MerchantTeaser {
  const MerchantTeaser({
    required this.total,
    required this.withoutNetwork,
    required this.ignoreCount,
  });

  factory MerchantTeaser.of(List<Merchant> merchants) {
    final parents = {for (final merchant in merchants) ?merchant.parentId};
    return MerchantTeaser(
      total: merchants.length,
      withoutNetwork: merchants.where((m) => m.parentId == null && !parents.contains(m.id)).length,
      ignoreCount: merchants.where((m) => m.ignoresItems).length,
    );
  }

  final int total;
  final int withoutNetwork;
  final int ignoreCount;

  bool get isEmpty => total == 0;
}

/// Home screen figures for one month and one currency.
class HomeDashboard {
  const HomeDashboard({
    required this.spent,
    required this.receiptCount,
    required this.prices,
    required this.priceRows,
    required this.wasteTotal,
    required this.wasteLeaves,
    required this.wasteTags,
    required this.frequent,
    required this.merchants,
  });

  final double spent;
  final int receiptCount;
  final PriceTeaser? prices;
  final List<PriceRow> priceRows;
  final double wasteTotal;
  final List<WasteSlice> wasteLeaves;
  final List<WasteSlice> wasteTags;
  final List<FrequentItem> frequent;
  final MerchantTeaser merchants;

  bool get isEmpty => receiptCount == 0;

  factory HomeDashboard.of({
    required List<ReceiptRecord> receipts,
    required List<Purchase> purchases,
    required List<CatalogProduct> products,
    required List<CatalogCategory> categories,
    required List<CatalogPosition> positions,
    required List<Merchant> merchants,
    required CatalogResolver resolver,
    required HomePeriod period,
    required String currency,
    required String fallbackMerchant,
  }) {
    final scopedReceipts = [
      for (final receipt in receipts)
        if (receipt.currency == currency && period.contains(receipt.at)) receipt,
    ];
    final scopedPurchases = [
      for (final purchase in purchases)
        if (purchase.currency == currency && period.contains(purchase.at)) purchase,
    ];
    final productById = products.indexBy((product) => product.id);

    final priceRows = buildPriceRows(
      points: collectPricePoints(
        receipts: scopedReceipts,
        resolver: resolver,
        merchants: merchants,
        fallbackMerchant: fallbackMerchant,
      ),
      products: productById,
      positions: positions,
    );
    final waste = buildWaste(
      purchases: scopedPurchases,
      products: productById,
      categories: categories.indexBy((category) => category.id),
    );

    return HomeDashboard(
      spent: scopedReceipts.fold<double>(0, (sum, receipt) => sum + receipt.grandTotal),
      receiptCount: scopedReceipts.length,
      prices: priceTeaserOf(priceRows),
      priceRows: priceRows,
      wasteTotal: waste.total,
      wasteLeaves: waste.leaves,
      wasteTags: waste.tags,
      frequent: _frequent(scopedPurchases, productById),
      merchants: MerchantTeaser.of(merchants),
    );
  }
}

List<FrequentItem> _frequent(List<Purchase> purchases, Map<String, CatalogProduct> products) {
  return [
    for (final tally in tallyPurchases(purchases))
      if (products[tally.productId] case final product?)
        FrequentItem(productId: product.id, name: product.name, count: tally.count, quantity: tally.quantity),
  ];
}
