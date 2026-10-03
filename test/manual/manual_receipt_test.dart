import 'package:checkscan/core/manual/manual_receipt.dart';
import 'package:flutter_test/flutter_test.dart';

ManualReceiptDraft _draft({List<ManualItemDraft>? items, String total = ''}) {
  return ManualReceiptDraft(
    merchantName: '  Рынок ',
    issuedAt: DateTime(2026, 9, 1, 10, 30),
    items: items,
    totalText: total,
  );
}

void main() {
  test('line sums stay integer: 0,5 x 178,50 rounds half up', () {
    final item = ManualItemDraft(name: 'Сыр', quantity: '0,5', price: '178,50');
    expect(item.sum, 8925);
  });

  test('fractional weight rounds the sum to the scale', () {
    final item = ManualItemDraft(name: 'Яблоки', quantity: '1,235', price: '99,90');
    expect(item.sum, 12338); // 123.3765 -> 123.38
  });

  test('empty quantity counts as one, zero quantity is invalid', () {
    expect(ManualItemDraft(name: 'a', price: '10').sum, 1000);
    expect(ManualItemDraft(name: 'a', quantity: '0', price: '10').sum, isNull);
  });

  test('total is the sum of the lines and scale is fixed', () {
    final built = buildManualReceipt(
      _draft(items: [
        ManualItemDraft(name: 'Молоко', quantity: '2', price: '89'),
        ManualItemDraft(name: 'Хлеб', price: '45,50'),
        ManualItemDraft(), // blank rows are skipped
      ]),
      id: 'm1',
    );
    final receipt = built.receipt!;
    expect(receipt.total, 22350);
    expect(receipt.scale, manualScale);
    expect(receipt.type, 'sale');
    expect(receipt.merchantName, 'Рынок');
    expect(receipt.items.map((item) => item.sum), [17800, 4550]);
    expect(receipt.items.first.quantity, 2);
  });

  test('without lines the typed total is used', () {
    final receipt = buildManualReceipt(_draft(total: '1247,5'), id: 'm1').receipt!;
    expect(receipt.total, 124750);
    expect(receipt.items, isEmpty);
  });

  test('rejects an empty or zero total and a half-filled line', () {
    expect(buildManualReceipt(_draft(), id: 'm1').error, ManualReceiptError.invalidTotal);
    expect(buildManualReceipt(_draft(total: '0'), id: 'm1').error, ManualReceiptError.invalidTotal);
    final noPrice = _draft(items: [ManualItemDraft(name: 'Хлеб')]);
    expect(buildManualReceipt(noPrice, id: 'm1').error, ManualReceiptError.invalidItem);
    final noName = _draft(items: [ManualItemDraft(price: '10')]);
    expect(buildManualReceipt(noName, id: 'm1').error, ManualReceiptError.invalidItem);
  });

  test('editing round-trips a receipt through the draft', () {
    final original = buildManualReceipt(
      _draft(items: [ManualItemDraft(name: 'Яблоки', quantity: '1,235', price: '99,90')]),
      id: 'm1',
    ).receipt!;
    final again = buildManualReceipt(ManualReceiptDraft.fromReceipt(original), id: 'm1').receipt!;
    expect(again.toJson(), original.toJson());
  });

  test('plainMinor drops trailing zeros', () {
    expect(plainMinor(8925, 2), '89.25');
    expect(plainMinor(10000, 2), '100');
    expect(plainMinor(1500, 3), '1.5');
  });
}
