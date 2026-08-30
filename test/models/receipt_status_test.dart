import 'package:checkscan/core/models/receipt_record.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';

EqReceipt _receipt({
  List<EqItem> items = const [],
  Map<String, dynamic> extensions = const {},
}) {
  return EqReceipt(
    id: 'r',
    issuedAt: DateTime(2026, 8, 28),
    currency: 'RSD',
    receiptType: 'sale',
    grandTotal: 10,
    items: items,
    extensions: extensions,
  );
}

void main() {
  test('empty items without a provider flag stay incomplete', () {
    expect(statusFromReceipt(_receipt()), ReceiptStatus.incomplete);
  });

  test('provider can mark success without items', () {
    expect(
      statusFromReceipt(_receipt(extensions: const {itemsUnavailableExtension: true})),
      ReceiptStatus.ok,
    );
  });

  test('rate limit stays incomplete even without items', () {
    expect(
      statusFromReceipt(_receipt(extensions: const {rateLimitedExtension: true})),
      ReceiptStatus.incomplete,
    );
  });
}
