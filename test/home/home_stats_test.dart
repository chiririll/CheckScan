import 'package:checkscan/core/format/format.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/features/home/home_period.dart';
import 'package:receipt_model/receipt_model.dart';
import 'package:flutter_test/flutter_test.dart';

ReceiptRecord _receipt({
  required String id,
  required String currency,
  required DateTime issuedAt,
  required int total,
}) {
  final receipt = Receipt(
    id: id,
    issuedAt: issuedAt,
    currency: currency,
    type: 'sale',
    merchantName: 'Магазин',
    total: total,
    items: const [ReceiptItem(name: 'Молоко', quantity: 1, price: 8000, sum: 8000)],
  );
  return ReceiptRecord(
    id: id,
    qrHash: 'h:$id',
    adapterId: 'eq_payload',
    status: ReceiptStatus.ok,
    issuedAt: issuedAt,
    merchantName: 'Магазин',
    total: total,
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
      _receipt(id: 'eur', currency: 'EUR', issuedAt: DateTime(2026, 8, 1), total: 1000),
      _receipt(id: 'rsd', currency: 'RSD', issuedAt: DateTime(2026, 8, 1), total: 2000),
      _receipt(id: 'rub', currency: 'RUB', issuedAt: DateTime(2026, 8, 1), total: 3000),
    ];
    expect(listCurrencies(receipts), ['RUB', 'RSD', 'EUR']);
  });

  test('formatCurrencyLabel uses local symbols', () {
    expect(formatCurrencyLabel('RUB'), '₽');
    expect(formatCurrencyLabel('RSD'), 'дин.');
    expect(formatCurrencyLabel('EUR'), 'EUR');
  });
}
