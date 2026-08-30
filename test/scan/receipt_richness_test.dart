import 'package:checkscan/core/scan/receipt_richness.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';

EqReceipt _receipt({
  String? merchant,
  String? taxId,
  double total = 0,
  List<EqItem> items = const [],
}) {
  return EqReceipt(
    id: 'r',
    issuedAt: DateTime(2026, 8, 28),
    currency: 'RSD',
    receiptType: 'sale',
    merchantName: merchant,
    taxId: taxId,
    grandTotal: total,
    items: items,
  );
}

void main() {
  test('items or merchant make the payload significantly richer', () {
    final empty = _receipt(total: 1749);
    final withItems = _receipt(
      total: 1749,
      merchant: 'Shop',
      items: const [EqItem(description: 'Voda', quantity: 1, unitPrice: 1749, totalPrice: 1749)],
    );
    expect(isSignificantlyRicher(withItems, empty), isTrue);
    expect(isSignificantlyRicher(empty, withItems), isFalse);
    expect(isSignificantlyRicher(empty, empty), isFalse);
  });

  test('same items with no new merchant stay as they were', () {
    final current = _receipt(
      merchant: 'Shop',
      total: 100,
      items: const [EqItem(description: 'A', quantity: 1, unitPrice: 100, totalPrice: 100)],
    );
    final same = _receipt(
      merchant: 'Shop',
      total: 100,
      items: const [EqItem(description: 'A', quantity: 1, unitPrice: 100, totalPrice: 100)],
    );
    expect(isSignificantlyRicher(same, current), isFalse);
  });
}
