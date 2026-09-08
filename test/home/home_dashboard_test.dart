import 'package:checkscan/core/catalog/catalog_category.dart';
import 'package:checkscan/core/catalog/catalog_position.dart';
import 'package:checkscan/core/catalog/catalog_product.dart';
import 'package:checkscan/core/catalog/catalog_resolver.dart';
import 'package:checkscan/core/catalog/catalog_tag.dart';
import 'package:checkscan/core/catalog/item_unit.dart';
import 'package:checkscan/core/catalog/purchase.dart';
import 'package:checkscan/core/merchant/merchant.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/features/home/home_dashboard.dart';
import 'package:checkscan/features/home/home_period.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';

ReceiptRecord _receipt({
  required String id,
  required DateTime issuedAt,
  required List<EqItem> items,
  String currency = 'RUB',
  String merchant = 'Магнит',
  String? merchantId,
}) {
  final total = items.fold<double>(0, (sum, item) => sum + item.totalPrice);
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
    merchantId: merchantId,
    grandTotal: total,
    currency: currency,
    itemCount: items.length,
    payload: receipt.encode(),
    scannedAt: issuedAt,
    rawQr: '{}',
  );
}

Purchase _purchase({
  required String id,
  required String checkId,
  required String productId,
  required DateTime at,
  required double total,
  double quantity = 1,
  String currency = 'RUB',
}) {
  return Purchase(
    id: id,
    checkId: checkId,
    productId: productId,
    quantity: quantity,
    unitPrice: total / quantity,
    total: total,
    currency: currency,
    issuedAt: at,
  );
}

void main() {
  const period = HomePeriod(year: 2026, month: 8);
  const productsTop = CatalogCategory(id: 'top', name: '#products', sortOrder: 0);
  const dairy = CatalogCategory(id: 'dairy', name: '#dairyEggs', parentId: 'top', sortOrder: 1);
  const snacks = CatalogCategory(id: 'snacks', name: '#snacks', parentId: 'top', sortOrder: 2);
  const cafe = CatalogCategory(id: 'cafe', name: '#cafe', sortOrder: 3);

  const milk = CatalogProduct(id: 'milk', name: 'Молоко', categoryId: 'dairy', unit: ItemUnit.l);
  const gummy = CatalogProduct(
    id: 'gummy',
    name: 'Мармелад',
    categoryId: 'snacks',
    unit: ItemUnit.g,
    tags: [CatalogTag(id: 't-snack', name: 'снеки')],
  );
  const coffee = CatalogProduct(id: 'coffee', name: 'Капучино', categoryId: 'cafe');

  const milk1 = CatalogPosition(id: 'p1', displayName: 'Молоко 1 л', productId: 'milk', unitSize: 1);
  const milk175 = CatalogPosition(id: 'p2', displayName: 'Молоко 1.75 л', productId: 'milk', unitSize: 1.75);
  const gummy300 = CatalogPosition(id: 'p3', displayName: 'Мармелад 300 г', productId: 'gummy', unitSize: 300);

  const resolver = CatalogResolver(
    byRawName: {
      'Молоко 1 л': 'p1',
      'Молоко 1.75 л': 'p2',
      'Мармелад 300 г': 'p3',
    },
    positions: {'p1': milk1, 'p2': milk175, 'p3': gummy300},
    products: {'milk': milk, 'gummy': gummy, 'coffee': coffee},
    categories: {'top': productsTop, 'dairy': dairy, 'snacks': snacks, 'cafe': cafe},
  );

  const magnet = Merchant(id: 'm1', name: 'Магнит');
  const maxiPoint = Merchant(id: 'm2', name: 'Maxi Нови Сад', parentId: 'net');
  const maxiNet = Merchant(id: 'net', name: 'Maxi');
  const cafeShop = Merchant(id: 'cafe1', name: 'Кафе', policy: MerchantPolicy.ignore);

  test('HomeDashboard filters receipts by month and currency', () {
    final receipts = [
      _receipt(id: 'rub-aug', issuedAt: DateTime(2026, 8, 10), items: const [
        EqItem(description: 'Молоко 1 л', quantity: 1, unitPrice: 80, totalPrice: 80),
      ]),
      _receipt(id: 'rub-jul', issuedAt: DateTime(2026, 7, 10), items: const [
        EqItem(description: 'Молоко 1 л', quantity: 1, unitPrice: 80, totalPrice: 80),
      ]),
      _receipt(
        id: 'rsd-aug',
        currency: 'RSD',
        issuedAt: DateTime(2026, 8, 10),
        items: const [EqItem(description: 'Молоко 1 л', quantity: 1, unitPrice: 200, totalPrice: 200)],
      ),
    ];
    final dash = HomeDashboard.of(
      receipts: receipts,
      purchases: const [],
      products: const [milk],
      categories: const [productsTop, dairy],
      positions: const [milk1],
      merchants: const [magnet],
      resolver: resolver,
      period: period,
      currency: 'RUB',
      fallbackMerchant: 'Чек',
    );
    expect(dash.spent, 80);
    expect(dash.receiptCount, 1);
    expect(dash.isEmpty, isFalse);
    expect(
      HomeDashboard.of(
        receipts: receipts,
        purchases: const [],
        products: const [milk],
        categories: const [productsTop, dairy],
        positions: const [milk1],
        merchants: const [magnet],
        resolver: resolver,
        period: const HomePeriod(year: 2026, month: 6),
        currency: 'RUB',
        fallbackMerchant: 'Чек',
      ).isEmpty,
      isTrue,
    );
  });

  test('₽/ед uses the large pack, not the average of collapsed purchases', () {
    final receipts = [
      _receipt(
        id: 'a',
        merchant: 'Магнит',
        merchantId: 'm1',
        issuedAt: DateTime(2026, 8, 10),
        items: const [
          EqItem(description: 'Молоко 1 л', quantity: 1, unitPrice: 80, totalPrice: 80),
          EqItem(description: 'Молоко 1.75 л', quantity: 1, unitPrice: 140, totalPrice: 140),
        ],
      ),
      _receipt(
        id: 'b',
        merchant: 'Maxi Нови Сад',
        merchantId: 'm2',
        issuedAt: DateTime(2026, 8, 11),
        items: const [EqItem(description: 'Молоко 1.75 л', quantity: 1, unitPrice: 150, totalPrice: 150)],
      ),
    ];
    final dash = HomeDashboard.of(
      receipts: receipts,
      purchases: const [],
      products: const [milk],
      categories: const [productsTop, dairy],
      positions: const [milk1, milk175],
      merchants: const [magnet, maxiPoint, maxiNet],
      resolver: resolver,
      period: period,
      currency: 'RUB',
      fallbackMerchant: 'Чек',
    );
    expect(dash.prices, isNotNull);
    expect(dash.prices!.productName, 'Молоко');
    expect(dash.prices!.unit, ItemUnit.l);
    expect(dash.prices!.perUnit, closeTo(140 / 1.75, 0.0001));
    expect(dash.prices!.networkName, 'Магнит');
    expect(dash.priceRows.single.networks.first.networkName, 'Магнит');
    expect(dash.priceRows.single.networks.first.perUnit, closeTo(140 / 1.75, 0.0001));
  });

  test('Чаще всего counts purchase visits, not raw receipt lines', () {
    final dash = HomeDashboard.of(
      receipts: const [],
      purchases: [
        _purchase(id: '1', checkId: 'a', productId: 'milk', at: DateTime(2026, 8, 1), total: 80),
        _purchase(id: '2', checkId: 'b', productId: 'milk', at: DateTime(2026, 8, 8), total: 90),
        _purchase(id: '3', checkId: 'c', productId: 'gummy', at: DateTime(2026, 8, 8), total: 50),
      ],
      products: const [milk, gummy],
      categories: const [productsTop, dairy, snacks],
      positions: const [],
      merchants: const [],
      resolver: CatalogResolver.empty,
      period: period,
      currency: 'RUB',
      fallbackMerchant: 'Чек',
    );
    expect(dash.frequent.first.name, 'Молоко');
    expect(dash.frequent.first.count, 2);
    expect(dash.frequent.last.name, 'Мармелад');
    expect(dash.frequent.last.count, 1);
  });

  test('Траты зря cuts by leaf and product tags, not the Savvy top', () {
    final dash = HomeDashboard.of(
      receipts: const [],
      purchases: [
        _purchase(id: '1', checkId: 'a', productId: 'milk', at: DateTime(2026, 8, 1), total: 80),
        _purchase(id: '2', checkId: 'b', productId: 'gummy', at: DateTime(2026, 8, 2), total: 50),
        _purchase(id: '3', checkId: 'c', productId: 'coffee', at: DateTime(2026, 8, 3), total: 200),
      ],
      products: const [milk, gummy, coffee],
      categories: const [productsTop, dairy, snacks, cafe],
      positions: const [],
      merchants: const [],
      resolver: CatalogResolver.empty,
      period: period,
      currency: 'RUB',
      fallbackMerchant: 'Чек',
    );
    expect(dash.wasteTotal, 130);
    expect(dash.wasteLeaves.map((e) => e.name), ['#dairyEggs', '#snacks']);
    expect(dash.wasteLeaves.first.spent, 80);
    expect(dash.wasteTags.single.name, 'снеки');
    expect(dash.wasteTags.single.spent, 50);
  });

  test('ignore merchants stay out of prices and the waste teaser still hides cafe top', () {
    final receipts = [
      _receipt(
        id: 'cafe',
        merchant: 'Кафе',
        merchantId: 'cafe1',
        issuedAt: DateTime(2026, 8, 1),
        items: const [EqItem(description: 'Капучино', quantity: 1, unitPrice: 200, totalPrice: 200)],
      ),
    ];
    final dash = HomeDashboard.of(
      receipts: receipts,
      purchases: const [],
      products: const [coffee],
      categories: const [cafe],
      positions: const [],
      merchants: const [cafeShop],
      resolver: resolver,
      period: period,
      currency: 'RUB',
      fallbackMerchant: 'Чек',
    );
    expect(dash.spent, 200);
    expect(dash.prices, isNull);
    expect(dash.wasteLeaves, isEmpty);
  });

  test('Магазины counts standalone points and ignore policy', () {
    final dash = HomeDashboard.of(
      receipts: const [],
      purchases: const [],
      products: const [],
      categories: const [],
      positions: const [],
      merchants: const [magnet, maxiPoint, maxiNet, cafeShop],
      resolver: CatalogResolver.empty,
      period: period,
      currency: 'RUB',
      fallbackMerchant: 'Чек',
    );
    expect(dash.merchants.total, 4);
    expect(dash.merchants.withoutNetwork, 2);
    expect(dash.merchants.ignoreCount, 1);
  });
}
