import 'package:checkscan/core/catalog/model/purchase.dart';
import 'package:checkscan/core/catalog/purchase_stats.dart';
import 'package:flutter_test/flutter_test.dart';

Purchase _purchase(String id, String productId, double quantity) {
  return Purchase(
    id: id,
    checkId: 'c$id',
    productId: productId,
    quantity: quantity,
    unitPrice: 10,
    total: 10 * quantity,
    currency: 'RUB',
  );
}

void main() {
  test('tallies receipts and quantity per product, most frequent first', () {
    final tallies = tallyPurchases([
      _purchase('1', 'bread', 1),
      _purchase('2', 'milk', 2),
      _purchase('3', 'milk', 1.5),
    ]);
    expect(tallies.map((t) => t.productId), ['milk', 'bread']);
    expect(tallies.first.count, 2);
    expect(tallies.first.quantity, 3.5);
    expect(tallies.last.count, 1);
  });

  test('no purchases → no tallies', () {
    expect(tallyPurchases(const []), isEmpty);
  });
}
