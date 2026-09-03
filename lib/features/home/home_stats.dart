import '../../core/catalog/catalog_resolver.dart';
import '../../core/models/receipt_record.dart';

class HomePeriod {
  const HomePeriod({required this.year, required this.month});

  factory HomePeriod.current([DateTime? now]) {
    final n = now ?? DateTime.now();
    return HomePeriod(year: n.year, month: n.month);
  }

  final int year;
  final int month;

  DateTime get asDate => DateTime(year, month);

  bool contains(DateTime date) => date.year == year && date.month == month;

  HomePeriod get previous => month == 1
      ? HomePeriod(year: year - 1, month: 12)
      : HomePeriod(year: year, month: month - 1);

  HomePeriod get next => month == 12
      ? HomePeriod(year: year + 1, month: 1)
      : HomePeriod(year: year, month: month + 1);

  bool isBefore(HomePeriod other) => year < other.year || (year == other.year && month < other.month);

  @override
  bool operator ==(Object other) => other is HomePeriod && year == other.year && month == other.month;

  @override
  int get hashCode => Object.hash(year, month);
}

class HomeItemStat {
  const HomeItemStat({required this.name, required this.count, this.productId});

  final String name;
  final int count;
  final String? productId;
}

class HomeCategoryStat {
  const HomeCategoryStat({required this.name, required this.spent, this.categoryId});

  final String name;
  final double spent;
  final String? categoryId;
}

class HomePriceStat {
  const HomePriceStat({required this.store, required this.price});

  final String store;
  final double price;
}

class HomeStats {
  const HomeStats({
    required this.spent,
    required this.receiptCount,
    required this.top,
    required this.cheaperKey,
    required this.cheaper,
    this.categories = const [],
  });

  final double spent;
  final int receiptCount;
  final List<HomeItemStat> top;
  final String? cheaperKey;
  final List<HomePriceStat> cheaper;
  final List<HomeCategoryStat> categories;

  bool get isEmpty => receiptCount == 0;

  factory HomeStats.of(
    List<ReceiptRecord> receipts, {
    required HomePeriod period,
    required String currency,
    required String fallbackMerchant,
    CatalogResolver resolver = CatalogResolver.empty,
    String uncategorized = 'Без категории',
  }) {
    final scoped = [
      for (final receipt in receipts)
        if (receipt.currency == currency && period.contains(receipt.issuedAt ?? receipt.scannedAt)) receipt,
    ];
    final spent = scoped.fold<double>(0, (sum, receipt) => sum + receipt.grandTotal);
    final topCounts = <String, int>{};
    final topIds = <String, String?>{};
    final positionCounts = <String, int>{};
    final prices = <String, Map<String, double>>{};
    final categorySpent = <String, double>{};
    final categoryIds = <String, String?>{};
    var hasMappedCategory = false;
    for (final record in scoped) {
      for (final item in record.receipt.items) {
        final topKey = resolver.topKey(item.description);
        topCounts[topKey] = (topCounts[topKey] ?? 0) + 1;
        topIds.putIfAbsent(topKey, () => resolver.resolve(item.description)?.product?.id);
        final cheaperKey = resolver.cheaperKey(item.description);
        positionCounts[cheaperKey] = (positionCounts[cheaperKey] ?? 0) + 1;
        final store = record.merchantName ??
            (record.providerLabel.isNotEmpty ? record.providerLabel : fallbackMerchant);
        final byStore = prices.putIfAbsent(cheaperKey, () => {});
        final current = byStore[store];
        if (current == null || item.unitPrice < current) {
          byStore[store] = item.unitPrice;
        }
        final categoryName = resolver.categoryName(item.description);
        if (categoryName != null) {
          hasMappedCategory = true;
          categorySpent[categoryName] = (categorySpent[categoryName] ?? 0) + item.totalPrice;
          categoryIds.putIfAbsent(categoryName, () => resolver.categoryId(item.description));
        } else {
          categorySpent[uncategorized] = (categorySpent[uncategorized] ?? 0) + item.totalPrice;
          categoryIds.putIfAbsent(uncategorized, () => null);
        }
      }
    }
    final ranked = topCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = [
      for (final entry in ranked.take(3)) HomeItemStat(name: entry.key, count: entry.value, productId: topIds[entry.key]),
    ];
    final rankedPositions = positionCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final cheaperKey = rankedPositions.isNotEmpty ? rankedPositions.first.key : null;
    final cheaper = <HomePriceStat>[];
    if (cheaperKey != null) {
      final stores = prices[cheaperKey]?.entries.toList() ?? [];
      stores.sort((a, b) => a.value.compareTo(b.value));
      cheaper.addAll([for (final entry in stores) HomePriceStat(store: entry.key, price: entry.value)]);
    }
    final categoryEntries = categorySpent.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final categories = hasMappedCategory
        ? [for (final entry in categoryEntries) HomeCategoryStat(name: entry.key, spent: entry.value, categoryId: categoryIds[entry.key])]
        : const <HomeCategoryStat>[];
    return HomeStats(
      spent: spent,
      receiptCount: scoped.length,
      top: top,
      cheaperKey: cheaperKey,
      cheaper: cheaper,
      categories: categories,
    );
  }
}

const _preferredCurrencies = ['RUB', 'RSD'];

List<String> listCurrencies(List<ReceiptRecord> receipts) {
  final seen = <String>{};
  for (final receipt in receipts) {
    if (receipt.currency.isNotEmpty) seen.add(receipt.currency);
  }
  final list = seen.toList();
  list.sort((a, b) {
    final ia = _preferredCurrencies.indexOf(a);
    final ib = _preferredCurrencies.indexOf(b);
    if (ia != -1 || ib != -1) {
      if (ia == -1) return 1;
      if (ib == -1) return -1;
      return ia.compareTo(ib);
    }
    return a.compareTo(b);
  });
  return list;
}
