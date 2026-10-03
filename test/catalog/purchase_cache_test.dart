import 'dart:io';

import 'package:checkscan/core/catalog/data/catalog_repository.dart';
import 'package:checkscan/core/merchant/merchant.dart';
import 'package:checkscan/core/merchant/merchant_repository.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _seq = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CheckScanDatabase database;
  late CatalogRepository catalog;
  late MerchantRepository merchants;
  late ReceiptRepository receipts;

  setUp(() {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_purchase_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    catalog = CatalogRepository(database: database);
    merchants = MerchantRepository(database: database);
    receipts = ReceiptRepository(database: database, merchants: merchants);
  });

  tearDown(() async {
    await database.close();
  });

  Future<ReceiptRecord> save({
    required String id,
    required List<EqItem> items,
    String merchant = 'Магнит',
    DateTime? issuedAt,
  }) {
    final total = items.fold<double>(0, (sum, item) => sum + item.totalPrice);
    return receipts.upsertParsed(
      qrHash: 'h:$id',
      adapterId: 'eq_payload',
      rawQr: id,
      receipt: EqReceipt(
        id: id,
        issuedAt: issuedAt ?? DateTime(2026, 8, 10),
        currency: 'RUB',
        receiptType: 'sale',
        merchantName: merchant,
        grandTotal: total,
        items: items,
      ),
      lastStatus: statusOk,
    );
  }

  test('rebuild writes one purchase per product in a check and skips unassigned', () async {
    final saved = await save(
      id: 'r1',
      items: const [
        EqItem(description: 'Молоко 1 л', quantity: 2, unitPrice: 80, totalPrice: 160),
        EqItem(description: 'Молоко 1.75 л', quantity: 1, unitPrice: 140, totalPrice: 140),
        EqItem(description: 'Хлеб', quantity: 1, unitPrice: 40, totalPrice: 40),
      ],
    );
    await catalog.ingestFromReceipts([saved], const <Merchant>[]);
    final positions = await catalog.listPositions();
    final milk = await catalog.createProduct(name: 'Молоко');
    await catalog.assignPosition(positions.firstWhere((e) => e.displayName.startsWith('Молоко 1 л')).id, milk.id);
    await catalog.assignPosition(positions.firstWhere((e) => e.displayName.startsWith('Молоко 1.75')).id, milk.id);

    await catalog.rebuildPurchases(receipts: [saved], merchants: const []);
    final purchases = await catalog.listPurchases();
    expect(purchases, hasLength(1));
    expect(purchases.single.productId, milk.id);
    expect(purchases.single.quantity, 3);
    expect(purchases.single.total, 300);
    expect(purchases.single.unitPrice, 100);
    expect(purchases.single.currency, 'RUB');
  });

  test('ignore merchant receipts do not enter the purchase cache', () async {
    final id = await merchants.resolve(name: 'Кафе Уют');
    await merchants.update(id, policy: MerchantPolicy.ignore);
    final saved = await save(
      id: 'cafe',
      merchant: 'Кафе Уют',
      items: const [EqItem(description: 'Капучино', quantity: 1, unitPrice: 200, totalPrice: 200)],
    );
    final all = await merchants.listAll();
    await catalog.ingestFromReceipts([saved], all);
    final product = await catalog.createProduct(name: 'Капучино');
    final positions = await catalog.listPositions();
    if (positions.isNotEmpty) {
      await catalog.assignPosition(positions.single.id, product.id);
    }
    await catalog.rebuildPurchases(receipts: [saved], merchants: all);
    expect(await catalog.listPurchases(), isEmpty);
  });

  test('deleteById drops purchase rows for that check', () async {
    final saved = await save(
      id: 'gone',
      items: const [EqItem(description: 'Хлеб', quantity: 1, unitPrice: 40, totalPrice: 40)],
    );
    await catalog.ingestFromReceipts([saved], const <Merchant>[]);
    final position = (await catalog.listPositions()).single;
    final product = await catalog.createProduct(name: 'Хлеб');
    await catalog.assignPosition(position.id, product.id);
    await catalog.rebuildPurchases(receipts: [saved], merchants: const []);
    expect(await catalog.listPurchases(), hasLength(1));
    await receipts.deleteById(saved.id);
    expect(await catalog.listPurchases(), isEmpty);
  });
}
