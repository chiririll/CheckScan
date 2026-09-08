import '../../core/catalog/catalog_category.dart';
import '../../core/catalog/catalog_position.dart';
import '../../core/catalog/catalog_product.dart';
import '../../core/catalog/catalog_resolver.dart';
import '../../core/catalog/item_unit.dart';
import '../../core/catalog/price_point.dart';
import '../../core/catalog/purchase.dart';
import '../../core/catalog/purchase_cache.dart';
import '../../core/merchant/merchant.dart';
import '../../core/models/receipt_record.dart';
import 'home_period.dart';

class PriceTeaser {
  const PriceTeaser({
    required this.productId,
    required this.productName,
    required this.perUnit,
    required this.unit,
    required this.networkName,
    this.shift,
  });

  final String productId;
  final String productName;
  final double perUnit;
  final ItemUnit unit;
  final String networkName;
  final double? shift;
}

class PriceRow {
  const PriceRow({
    required this.productId,
    required this.productName,
    required this.perUnit,
    required this.unit,
    required this.networkName,
    this.shift,
    this.networks = const [],
  });

  final String productId;
  final String productName;
  final double perUnit;
  final ItemUnit unit;
  final String networkName;
  final double? shift;
  final List<NetworkPrice> networks;
}

class WasteSlice {
  const WasteSlice({required this.id, required this.name, required this.spent});

  final String id;
  final String name;
  final double spent;
}

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

  final int total;
  final int withoutNetwork;
  final int ignoreCount;

  bool get isEmpty => total == 0;
}

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
        if (receipt.currency == currency && period.contains(receipt.issuedAt ?? receipt.scannedAt)) receipt,
    ];
    final spent = scopedReceipts.fold<double>(0, (sum, receipt) => sum + receipt.grandTotal);
    final scopedPurchases = [
      for (final purchase in purchases)
        if (purchase.currency == currency && period.contains(purchase.at)) purchase,
    ];

    final productById = {for (final product in products) product.id: product};
    final categoryById = {for (final category in categories) category.id: category};
    final hasChildren = {for (final category in categories) if (category.parentId != null) category.parentId!};

    final ignoreIds = ignoreMerchantIdsOf(merchants);
    final points = collectPricePoints(
      receipts: scopedReceipts,
      resolver: resolver,
      merchants: merchants,
      ignoreMerchantIds: ignoreIds,
      fallbackMerchant: fallbackMerchant,
    );

    final priceRows = _priceRows(
      points: points,
      products: productById,
      positions: positions,
    );
    final prices = priceRows.isEmpty ? null : _priceTeaser(priceRows);

    final waste = _waste(
      purchases: scopedPurchases,
      products: productById,
      categories: categoryById,
      hasChildren: hasChildren,
    );

    final frequent = _frequent(purchases: scopedPurchases, products: productById);
    final merchantTeaser = _merchantTeaser(merchants);

    return HomeDashboard(
      spent: spent,
      receiptCount: scopedReceipts.length,
      prices: prices,
      priceRows: priceRows,
      wasteTotal: waste.total,
      wasteLeaves: waste.leaves,
      wasteTags: waste.tags,
      frequent: frequent,
      merchants: merchantTeaser,
    );
  }
}

List<PriceRow> _priceRows({
  required List<PricePoint> points,
  required Map<String, CatalogProduct> products,
  required List<CatalogPosition> positions,
}) {
  final byProduct = <String, List<PricePoint>>{};
  for (final point in points) {
    byProduct.putIfAbsent(point.productId, () => []).add(point);
  }
  final rows = <PriceRow>[];
  for (final entry in byProduct.entries) {
    final product = products[entry.key];
    if (product == null) continue;
    final headline = headlinePrice(productPoints: entry.value, items: positions, product: product);
    if (headline?.perUnit == null || headline?.unit == null) continue;
    final networks = cheaperNetworks(entry.value);
    rows.add(
      PriceRow(
        productId: product.id,
        productName: product.name,
        perUnit: headline!.perUnit!,
        unit: headline.unit!,
        networkName: networks.isEmpty ? headline.networkName : networks.first.networkName,
        shift: priceShift(entry.value),
        networks: networks,
      ),
    );
  }
  rows.sort((a, b) {
    final cmp = b.networks.length.compareTo(a.networks.length);
    if (cmp != 0) return cmp;
    return a.productName.toLowerCase().compareTo(b.productName.toLowerCase());
  });
  return rows;
}

PriceTeaser _priceTeaser(List<PriceRow> rows) {
  PriceRow best = rows.first;
  var bestSpread = _spread(best);
  for (final row in rows.skip(1)) {
    final spread = _spread(row);
    if (spread > bestSpread) {
      best = row;
      bestSpread = spread;
    }
  }
  return PriceTeaser(
    productId: best.productId,
    productName: best.productName,
    perUnit: best.networks.isNotEmpty ? best.networks.first.perUnit : best.perUnit,
    unit: best.unit,
    networkName: best.networkName,
    shift: best.shift,
  );
}

double _spread(PriceRow row) {
  if (row.networks.length < 2) return 0;
  return row.networks.last.perUnit - row.networks.first.perUnit;
}

({double total, List<WasteSlice> leaves, List<WasteSlice> tags}) _waste({
  required List<Purchase> purchases,
  required Map<String, CatalogProduct> products,
  required Map<String, CatalogCategory> categories,
  required Set<String?> hasChildren,
}) {
  final leafSpent = <String, double>{};
  final tagSpent = <String, double>{};
  final leafNames = <String, String>{};
  final tagNames = <String, String>{};
  var total = 0.0;
  final counted = <String>{};

  for (final purchase in purchases) {
    final product = products[purchase.productId];
    if (product == null) continue;
    final category = product.categoryId == null ? null : categories[product.categoryId!];
    final isLeaf = category != null && !hasChildren.contains(category.id) && !category.isTop;
    if (isLeaf) {
      leafSpent[category.id] = (leafSpent[category.id] ?? 0) + purchase.total;
      leafNames[category.id] = category.name;
    }
    for (final tag in product.tags) {
      tagSpent[tag.id] = (tagSpent[tag.id] ?? 0) + purchase.total;
      tagNames[tag.id] = tag.name;
    }
    if ((isLeaf || product.tags.isNotEmpty) && counted.add(purchase.id)) {
      total += purchase.total;
    }
  }

  List<WasteSlice> ranked(Map<String, double> spent, Map<String, String> names) {
    final entries = spent.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [for (final entry in entries) WasteSlice(id: entry.key, name: names[entry.key] ?? entry.key, spent: entry.value)];
  }

  return (total: total, leaves: ranked(leafSpent, leafNames), tags: ranked(tagSpent, tagNames));
}

List<FrequentItem> _frequent({
  required List<Purchase> purchases,
  required Map<String, CatalogProduct> products,
}) {
  final counts = <String, int>{};
  final qty = <String, double>{};
  for (final purchase in purchases) {
    counts[purchase.productId] = (counts[purchase.productId] ?? 0) + 1;
    qty[purchase.productId] = (qty[purchase.productId] ?? 0) + purchase.quantity;
  }
  final ranked = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final entry in ranked)
      if (products[entry.key] != null)
        FrequentItem(
          productId: entry.key,
          name: products[entry.key]!.name,
          count: entry.value,
          quantity: qty[entry.key] ?? 0,
        ),
  ];
}

MerchantTeaser _merchantTeaser(List<Merchant> merchants) {
  final parents = {for (final merchant in merchants) if (merchant.parentId != null) merchant.parentId!};
  var withoutNetwork = 0;
  var ignoreCount = 0;
  for (final merchant in merchants) {
    if (merchant.ignoresItems) ignoreCount += 1;
    if (merchant.parentId == null && !parents.contains(merchant.id)) withoutNetwork += 1;
  }
  return MerchantTeaser(total: merchants.length, withoutNetwork: withoutNetwork, ignoreCount: ignoreCount);
}
