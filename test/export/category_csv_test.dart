import 'dart:io';

import 'package:checkscan/core/catalog/catalog_category.dart';
import 'package:checkscan/core/catalog/catalog_position.dart';
import 'package:checkscan/core/catalog/catalog_product.dart';
import 'package:checkscan/core/catalog/catalog_resolver.dart';
import 'package:checkscan/core/export/category_csv.dart';
import 'package:checkscan/core/export/category_csv_share.dart';
import 'package:checkscan/core/merchant/merchant.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

ReceiptRecord _receipt({
  required String id,
  required List<EqItem> items,
  String merchant = 'Магнит',
  String? merchantId,
  double? total,
}) {
  final sum = total ?? items.fold<double>(0, (acc, item) => acc + item.totalPrice);
  final issued = DateTime(2026, 8, 28, 15, 42);
  final receipt = EqReceipt(
    id: id,
    issuedAt: issued,
    currency: 'RUB',
    receiptType: 'sale',
    merchantName: merchant,
    grandTotal: sum,
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
    grandTotal: sum,
    currency: 'RUB',
    itemCount: items.length,
    payload: receipt.encode(),
    scannedAt: issued,
    rawQr: '{}',
  );
}

void main() {
  const products = CatalogCategory(id: 'top', name: '#products', sortOrder: 0);
  const household = CatalogCategory(id: 'house', name: '#household', sortOrder: 1);
  const cafe = CatalogCategory(id: 'cafe', name: '#cafe', sortOrder: 2);
  const dairy = CatalogCategory(id: 'dairy', name: '#dairyEggs', parentId: 'top', sortOrder: 3);
  const home = CatalogCategory(id: 'home', name: '#home', parentId: 'house', sortOrder: 4);

  const milk = CatalogProduct(id: 'milk', name: 'Молоко', categoryId: 'dairy');
  const sponge = CatalogProduct(id: 'sponge', name: 'Губка', categoryId: 'home');
  const milkItem = CatalogPosition(id: 'i1', displayName: 'Молоко 1 л', productId: 'milk');
  const spongeItem = CatalogPosition(id: 'i2', displayName: 'Губка', productId: 'sponge');

  const resolver = CatalogResolver(
    byRawName: {
      'Молоко 1 л': 'i1',
      'Губка': 'i2',
    },
    positions: {'i1': milkItem, 'i2': spongeItem},
    products: {'milk': milk, 'sponge': sponge},
    categories: {'top': products, 'house': household, 'cafe': cafe, 'dairy': dairy, 'home': home},
  );

  const magnet = Merchant(id: 'm1', name: 'Магнит');
  const konoba = Merchant(id: 'm2', name: 'Konoba', policy: MerchantPolicy.ignore, categoryId: 'cafe');

  test('one top stays one row with human product names as reference', () {
    final rows = buildCategoryExport(
      receipts: [
        _receipt(id: 'r1', merchantId: 'm1', items: const [
          EqItem(description: 'Молоко 1 л', quantity: 2, unitPrice: 80, totalPrice: 160),
        ]),
      ],
      resolver: resolver,
      categories: const [products, household, cafe, dairy, home],
      merchants: const [magnet],
    );
    expect(rows, hasLength(1));
    expect(rows.single.categoryKey, '#products');
    expect(rows.single.amount, 160);
    expect(rows.single.items, ['Молоко × 2']);
  });

  test('splits a receipt when leaves belong to different tops', () {
    final rows = buildCategoryExport(
      receipts: [
        _receipt(id: 'r1', merchantId: 'm1', items: const [
          EqItem(description: 'Молоко 1 л', quantity: 1, unitPrice: 80, totalPrice: 80),
          EqItem(description: 'Губка', quantity: 1, unitPrice: 40, totalPrice: 40),
        ]),
      ],
      resolver: resolver,
      categories: const [products, household, cafe, dairy, home],
      merchants: const [magnet],
    );
    expect(rows, hasLength(2));
    expect(rows.map((row) => row.categoryKey).toSet(), {'#products', '#household'});
    expect(rows.firstWhere((row) => row.categoryKey == '#products').amount, 80);
    expect(rows.firstWhere((row) => row.categoryKey == '#household').amount, 40);
    expect(rows.any((row) => row.categoryKey == '#dairyEggs'), isFalse);
  });

  test('ignore merchant is one top-level sum without line items', () {
    final rows = buildCategoryExport(
      receipts: [
        _receipt(
          id: 'cafe',
          merchant: 'Konoba',
          merchantId: 'm2',
          total: 450,
          items: const [EqItem(description: 'Цезарь', quantity: 1, unitPrice: 450, totalPrice: 450)],
        ),
      ],
      resolver: resolver,
      categories: const [products, household, cafe, dairy, home],
      merchants: const [konoba],
    );
    expect(rows, hasLength(1));
    expect(rows.single.categoryKey, '#cafe');
    expect(rows.single.amount, 450);
    expect(rows.single.items, isEmpty);
  });

  test('encodeCategoryCsv writes localized tops and escapes cells', () {
    final csv = encodeCategoryCsv(
      [
        CategoryExportRow(
          at: DateTime(2026, 8, 28),
          merchant: 'Магнит, ТЦ',
          receiptId: 'r1',
          categoryKey: '#products',
          amount: 80,
          currency: 'RUB',
          items: const ['Молоко × 1'],
        ),
      ],
      categoryName: (key) => key == '#products' ? 'Продукты' : key,
    );
    expect(
      csv,
      'date,merchant,category_key,category,amount,currency,items\n'
      '2026-08-28,"Магнит, ТЦ",#products,Продукты,80.00,RUB,Молоко × 1\n',
    );
  });

  test('writeCategoryCsvFile uses the calendar date', () async {
    final dir = Directory.systemTemp.createTempSync('checkscan_csv_');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    final file = await writeCategoryCsvFile(
      rows: const [],
      directory: dir,
      now: DateTime(2026, 9, 8),
    );
    expect(p.basename(file.path), 'checkscan-categories-2026-09-08.csv');
    expect(file.readAsStringSync(), 'date,merchant,category_key,category,amount,currency,items\n');
  });
}
