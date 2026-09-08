import 'dart:convert';

import 'package:checkscan/core/catalog/catalog_position.dart';
import 'package:checkscan/core/catalog/catalog_product.dart';
import 'package:checkscan/core/catalog/item_unit.dart';
import 'package:checkscan/core/manual/manual_receipt.dart';
import 'package:crypto/crypto.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manualStorageKey is sha256 of the first saved eQ', () {
    final receipt = buildManualReceipt(
      id: 'm1',
      issuedAt: DateTime.utc(2026, 9, 8, 10),
      merchantName: 'Рынок',
      items: const [EqItem(description: 'Молоко 1 л', quantity: 2, unitPrice: 80, totalPrice: 160)],
    );
    final expected = sha256.convert(utf8.encode(receipt.encode())).toString();
    expect(manualStorageKey(receipt), 'manual:$expected');
    expect(manualStorageKey(receipt), manualStorageKey(receipt));
  });

  test('edits would keep the first key only if the caller reuses it', () {
    final first = buildManualReceipt(
      id: 'm1',
      issuedAt: DateTime.utc(2026, 9, 8, 10),
      merchantName: 'Рынок',
      items: const [EqItem(description: 'Молоко 1 л', quantity: 1, unitPrice: 80, totalPrice: 80)],
    );
    final edited = first.copyWith(
      items: const [EqItem(description: 'Молоко 1 л', quantity: 3, unitPrice: 80, totalPrice: 240)],
      grandTotal: 240,
    );
    expect(manualStorageKey(first), isNot(manualStorageKey(edited)));
  });

  test('lineDescriptionFor reuses the cashier title', () {
    const product = CatalogProduct(id: '1', name: 'Молоко', unit: ItemUnit.l);
    const items = [
      CatalogPosition(id: 'a', displayName: 'Молоко 1.75 л', productId: '1', unitSize: 1.75),
      CatalogPosition(id: 'b', displayName: 'Молоко 1 л', productId: '1', unitSize: 1),
    ];
    expect(lineDescriptionFor(product: product, positions: items), 'Молоко 1.75 л');
  });

  test('lineDescriptionFor falls back to the product name', () {
    const product = CatalogProduct(id: '1', name: 'Молоко');
    expect(lineDescriptionFor(product: product, positions: const []), 'Молоко');
  });
}
