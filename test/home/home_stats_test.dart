import 'package:checkscan/core/format/format.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/features/home/home_dashboard.dart';
import 'package:checkscan/features/home/home_period.dart';
import 'package:receipt_model/receipt_model.dart';
import 'package:flutter_test/flutter_test.dart';

ReceiptRecord _receipt({
  required String id,
  required String currency,
  required DateTime issuedAt,
  required int total,
  int scale = 2,
  String type = 'sale',
  bool itemsUnavailable = false,
}) {
  final receipt = Receipt(
    id: id,
    issuedAt: issuedAt,
    currency: currency,
    scale: scale,
    type: type,
    merchantName: 'Магазин',
    total: total,
    items: itemsUnavailable ? const [] : const [ReceiptItem(name: 'Молоко', quantity: 1, price: 8000, sum: 8000)],
    extensions: itemsUnavailable ? const {itemsUnavailableExtension: true} : const {},
  );
  return ReceiptRecord(
    id: id,
    qrHash: 'h:$id',
    adapterId: 'eq_payload',
    status: itemsUnavailable ? ReceiptStatus.incomplete : ReceiptStatus.ok,
    issuedAt: issuedAt,
    merchantName: 'Магазин',
    total: total,
    currency: currency,
    scale: scale,
    itemCount: itemsUnavailable ? 0 : 1,
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

  test('spent sums receipts of one currency at the finest provider scale', () {
    final dash = HomeDashboard.of(
      receipts: [
        _receipt(id: 'kopecks', currency: 'RUB', issuedAt: DateTime(2026, 8, 1), total: 8999),
        _receipt(id: 'rubles', currency: 'RUB', issuedAt: DateTime(2026, 8, 2), total: 100, scale: 0),
        _receipt(id: 'other', currency: 'RSD', issuedAt: DateTime(2026, 8, 3), total: 5000),
      ],
      merchants: const [],
      period: const HomePeriod(year: 2026, month: 8),
      currency: 'RUB',
    );
    expect(dash.spentScale, 2);
    expect(dash.spent, 18999);
    expect(dash.receiptCount, 2);
  });

  test('a refund reduces spent and shows as a negative amount', () {
    final refund = _receipt(id: 'ref', currency: 'RSD', issuedAt: DateTime(2026, 8, 2), total: 2000, type: 'refund');
    final dash = HomeDashboard.of(
      receipts: [
        _receipt(id: 'buy', currency: 'RSD', issuedAt: DateTime(2026, 8, 1), total: 5000),
        refund,
      ],
      merchants: const [],
      period: const HomePeriod(year: 2026, month: 8),
      currency: 'RSD',
    );
    expect(dash.spent, 3000);
    expect(refund.signedTotal, -2000);
  });

  test('spent goes negative when refunds exceed purchases in a period', () {
    final dash = HomeDashboard.of(
      receipts: [
        _receipt(id: 'ref', currency: 'RSD', issuedAt: DateTime(2026, 8, 2), total: 2000, type: 'refund'),
      ],
      merchants: const [],
      period: const HomePeriod(year: 2026, month: 8),
      currency: 'RSD',
    );
    expect(dash.spent, -2000);
  });

  test('formatMoney marks returned money with a plus', () {
    expect(formatMoney(223984, scale: 2, currency: 'RSD', plus: true), '+2 239,84 дин.');
    expect(formatMoney(223984, scale: 2, currency: 'RSD'), '2 239,84 дин.');
    expect(formatMoney(0, scale: 2, plus: true), '0 ₽');
  });

  test('a receipt without items from the provider is not flagged as missing', () {
    final record = _receipt(
      id: 'r',
      currency: 'RSD',
      issuedAt: DateTime(2026, 8, 1),
      total: 100,
      type: 'refund',
      itemsUnavailable: true,
    );
    expect(record.itemsUnavailable, isTrue);
    expect(record.missingRemoteItems, isFalse);
  });
}
