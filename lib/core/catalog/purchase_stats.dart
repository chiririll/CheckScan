import 'model/purchase.dart';

class PurchaseTally {
  PurchaseTally(this.productId);

  final String productId;
  int count = 0;
  double quantity = 0;
}

/// Per product: how many receipts bought it and how much in total, most frequent first.
List<PurchaseTally> tallyPurchases(Iterable<Purchase> purchases) {
  final tallies = <String, PurchaseTally>{};
  for (final purchase in purchases) {
    final tally = tallies.putIfAbsent(purchase.productId, () => PurchaseTally(purchase.productId));
    tally.count += 1;
    tally.quantity += purchase.quantity;
  }
  return tallies.values.toList()..sort((a, b) => b.count.compareTo(a.count));
}
