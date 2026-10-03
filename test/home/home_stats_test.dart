import 'package:checkscan/core/format/format.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/features/home/home_period.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';

ReceiptRecord _receipt({
  required String id,
  required String currency,
  required DateTime issuedAt,
  required double total,
}) {
  final receipt = EqReceipt(
    id: id,
    issuedAt: issuedAt,
    currency: currency,
    receiptType: 'sale',
    merchantName: 'Магазин',
    grandTotal: total,
    items: const [EqItem(description: 'Молоко', quantity: 1, unitPrice: 80, totalPrice: 80)],
  );
  return ReceiptRecord(
    id: id,
    qrHash: 'h:$id',
    adapterId: 'eq_payload',
    status: ReceiptStatus.ok,
    issuedAt: issuedAt,
    merchantName: 'Магазин',
    grandTotal: total,
    currency: currency,
    itemCount: 1,
    payload: receipt.encode(),
    scannedAt: issuedAt,
    rawQr: '{}',
  );
}

void main() {
  test('HomePeriod wraps year on previous and next', () {
    expect(const HomePeriod(year: 2026, month: 1).previous, const HomePeriod(year: 2025, month: 12));
    expect(const HomePeriod(year: 2025, month: 12).next, const HomePeriod(year: 2026, month: 1));
  });

  test('HomePeriod.contains matches year and month', () {
    const period = HomePeriod(year: 2026, month: 8);
    expect(period.contains(DateTime(2026, 8, 31)), isTrue);
    expect(period.contains(DateTime(2026, 7, 31)), isFalse);
  });

  test('listCurrencies prefers RUB then RSD', () {
    final receipts = [
      _receipt(id: 'eur', currency: 'EUR', issuedAt: DateTime(2026, 8, 1), total: 10),
      _receipt(id: 'rsd', currency: 'RSD', issuedAt: DateTime(2026, 8, 1), total: 20),
      _receipt(id: 'rub', currency: 'RUB', issuedAt: DateTime(2026, 8, 1), total: 30),
    ];
    expect(listCurrencies(receipts), ['RUB', 'RSD', 'EUR']);
  });

  test('formatCurrencyLabel uses local symbols', () {
    expect(formatCurrencyLabel('RUB'), '₽');
    expect(formatCurrencyLabel('RSD'), 'дин.');
    expect(formatCurrencyLabel('EUR'), 'EUR');
  });
}
