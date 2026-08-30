import 'package:checkscan/core/format.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/features/home/home_stats.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';

ReceiptRecord _receipt({
  required String id,
  required String currency,
  required DateTime issuedAt,
  required double total,
  String merchant = 'Магазин',
  List<EqItem> items = const [EqItem(description: 'Молоко', quantity: 1, unitPrice: 80, totalPrice: 80)],
}) {
  final receipt = EqReceipt(
    id: id,
    issuedAt: issuedAt,
    currency: currency,
    receiptType: 'sale',
    merchantName: merchant,
    grandTotal: total,
    items: items,
  );
  return ReceiptRecord(
    id: id,
    qrHash: 'h:$id',
    adapterId: 'eq_payload',
    status: ReceiptStatus.ok,
    issuedAt: issuedAt,
    merchantName: merchant,
    grandTotal: total,
    currency: currency,
    itemCount: items.length,
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

  test('HomeStats filters by currency and period', () {
    const period = HomePeriod(year: 2026, month: 8);
    final receipts = [
      _receipt(id: 'rub-aug', currency: 'RUB', issuedAt: DateTime(2026, 8, 10), total: 100),
      _receipt(id: 'rub-jul', currency: 'RUB', issuedAt: DateTime(2026, 7, 10), total: 50),
      _receipt(id: 'rsd-aug', currency: 'RSD', issuedAt: DateTime(2026, 8, 10), total: 200),
    ];

    final rub = HomeStats.of(receipts, period: period, currency: 'RUB', fallbackMerchant: 'Чек');
    expect(rub.spent, 100);
    expect(rub.receiptCount, 1);

    final rsd = HomeStats.of(receipts, period: period, currency: 'RSD', fallbackMerchant: 'Чек');
    expect(rsd.spent, 200);
    expect(rsd.receiptCount, 1);

    final empty = HomeStats.of(receipts, period: const HomePeriod(year: 2026, month: 6), currency: 'RUB', fallbackMerchant: 'Чек');
    expect(empty.isEmpty, isTrue);
  });

  test('formatCurrencyLabel uses local symbols', () {
    expect(formatCurrencyLabel('RUB'), '₽');
    expect(formatCurrencyLabel('RSD'), 'дин.');
    expect(formatCurrencyLabel('EUR'), 'EUR');
  });
}
