import 'package:checkscan/core/catalog/catalog_category.dart';
import 'package:checkscan/core/catalog/catalog_position.dart';
import 'package:checkscan/core/catalog/catalog_product.dart';
import 'package:checkscan/core/catalog/catalog_resolver.dart';
import 'package:checkscan/core/catalog/item_unit.dart';
import 'package:checkscan/core/catalog/purchase.dart';
import 'package:checkscan/core/merchant/merchant.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/shopping/shopping_list.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';

ReceiptRecord _receipt({
  required String id,
  required List<EqItem> items,
  String merchant = 'Магнит',
  String? merchantId,
}) {
  final total = items.fold<double>(0, (sum, item) => sum + item.totalPrice);
  final issued = DateTime(2026, 8, 10);
  final receipt = EqReceipt(
    id: id,
    issuedAt: issued,
    currency: 'RUB',
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
    issuedAt: issued,
    merchantName: merchant,
    merchantId: merchantId,
    grandTotal: total,
    currency: 'RUB',
    itemCount: items.length,
    payload: receipt.encode(),
    scannedAt: issued,
    rawQr: '{}',
  );
}

Purchase _purchase({required String productId, required double quantity, String id = 'p'}) {
  return Purchase(
    id: id,
    checkId: 'c',
    productId: productId,
    quantity: quantity,
    unitPrice: 80,
    total: 80 * quantity,
    currency: 'RUB',
    issuedAt: DateTime(2026, 8, 10),
  );
}

void main() {
  const milk = CatalogProduct(id: 'milk', name: 'Молоко', unit: ItemUnit.l);
  const candy = CatalogProduct(id: 'candy', name: 'Мармелад');
  const milk1 = CatalogPosition(id: 'i1', displayName: 'Молоко 1 л', productId: 'milk', unitSize: 1);
  const candyItem = CatalogPosition(id: 'i2', displayName: 'Мармелад', productId: 'candy');
  const magnet = Merchant(id: 'm1', name: 'Магнит');
  const maxi = Merchant(id: 'm2', name: 'Maxi');

  const resolver = CatalogResolver(
    byRawName: {'Молоко 1 л': 'i1'},
    positions: {'i1': milk1},
    products: {'milk': milk},
    categories: {'top': CatalogCategory(id: 'top', name: '#products', sortOrder: 0)},
  );

  test('empty when product or unitSize is not honest', () {
    final lines = buildShoppingList(
      purchases: [_purchase(productId: 'candy', quantity: 3)],
      products: const [candy],
      positions: const [candyItem],
      receipts: const [],
      resolver: CatalogResolver.empty,
      merchants: const [magnet],
      fallbackMerchant: 'Чек',
    );
    expect(lines, isEmpty);
  });

  test('empty when there are purchases but no catalog product', () {
    final lines = buildShoppingList(
      purchases: [_purchase(productId: 'ghost', quantity: 2)],
      products: const [milk],
      positions: const [milk1],
      receipts: const [],
      resolver: resolver,
      merchants: const [magnet],
      fallbackMerchant: 'Чек',
    );
    expect(lines, isEmpty);
  });

  test('fills packs from tempo when pack size is honest', () {
    final lines = buildShoppingList(
      purchases: [
        _purchase(id: 'a', productId: 'milk', quantity: 2),
        _purchase(id: 'b', productId: 'milk', quantity: 3),
      ],
      products: const [milk],
      positions: const [milk1],
      receipts: const [],
      resolver: resolver,
      merchants: const [magnet],
      fallbackMerchant: 'Чек',
    );
    expect(lines, hasLength(1));
    expect(lines.single.productId, 'milk');
    expect(lines.single.packs, 3);
    expect(lines.single.packSize, 1);
    expect(lines.single.unit, ItemUnit.l);
  });

  test('names the cheaper network from honest unit prices', () {
    final receipts = [
      _receipt(
        id: 'a',
        merchant: 'Магнит',
        merchantId: 'm1',
        items: const [EqItem(description: 'Молоко 1 л', quantity: 1, unitPrice: 90, totalPrice: 90)],
      ),
      _receipt(
        id: 'b',
        merchant: 'Maxi',
        merchantId: 'm2',
        items: const [EqItem(description: 'Молоко 1 л', quantity: 1, unitPrice: 70, totalPrice: 70)],
      ),
    ];
    final lines = buildShoppingList(
      purchases: [_purchase(productId: 'milk', quantity: 1)],
      products: const [milk],
      positions: const [milk1],
      receipts: receipts,
      resolver: resolver,
      merchants: const [magnet, maxi],
      fallbackMerchant: 'Чек',
    );
    expect(lines.single.cheaperNetwork, 'Maxi');
  });
}
