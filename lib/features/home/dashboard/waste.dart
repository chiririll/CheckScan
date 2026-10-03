import '../../../core/catalog/model/catalog_category.dart';
import '../../../core/catalog/model/catalog_product.dart';
import '../../../core/catalog/model/purchase.dart';

class WasteSlice {
  const WasteSlice({required this.id, required this.name, required this.spent});

  final String id;
  final String name;
  final double spent;
}

class WasteSummary {
  const WasteSummary({required this.total, required this.leaves, required this.tags});

  /// Each purchase counts once, even when it lands in a leaf and in tags.
  final double total;
  final List<WasteSlice> leaves;
  final List<WasteSlice> tags;
}

/// Spending by leaf category and by product tag, biggest first.
WasteSummary buildWaste({
  required List<Purchase> purchases,
  required Map<String, CatalogProduct> products,
  required Map<String, CatalogCategory> categories,
}) {
  final parents = {for (final category in categories.values) ?category.parentId};
  final leaves = _Totals();
  final tags = _Totals();
  var total = 0.0;
  final counted = <String>{};

  for (final purchase in purchases) {
    final product = products[purchase.productId];
    if (product == null) continue;
    final category = product.categoryId == null ? null : categories[product.categoryId!];
    final isLeaf = category != null && !parents.contains(category.id) && !category.isTop;
    if (isLeaf) leaves.add(category.id, category.name, purchase.total);
    for (final tag in product.tags) {
      tags.add(tag.id, tag.name, purchase.total);
    }
    if ((isLeaf || product.tags.isNotEmpty) && counted.add(purchase.id)) total += purchase.total;
  }
  return WasteSummary(total: total, leaves: leaves.ranked(), tags: tags.ranked());
}

class _Totals {
  final _spent = <String, double>{};
  final _names = <String, String>{};

  void add(String id, String name, double amount) {
    _spent[id] = (_spent[id] ?? 0) + amount;
    _names[id] = name;
  }

  List<WasteSlice> ranked() {
    final entries = _spent.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [for (final entry in entries) WasteSlice(id: entry.key, name: _names[entry.key]!, spent: entry.value)];
  }
}
