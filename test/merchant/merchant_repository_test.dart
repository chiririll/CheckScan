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
  late MerchantRepository merchants;
  late CatalogRepository catalog;
  late ReceiptRepository receipts;

  setUp(() {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_merchant_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    merchants = MerchantRepository(database: database);
    catalog = CatalogRepository(database: database);
    receipts = ReceiptRepository(database: database, merchants: merchants);
  });

  tearDown(() async {
    await database.close();
  });

  test('starts with no merchants', () async {
    expect(await merchants.listAll(), isEmpty);
  });

  test('resolve creates a merchant from the receipt name', () async {
    final id = await merchants.resolve(name: 'DELHAIZE SERBIA DOO BEOGRAD');
    final merchant = await merchants.findById(id);
    expect(merchant?.name, 'DELHAIZE SERBIA DOO BEOGRAD');
    expect(merchant?.policy, MerchantPolicy.parse);
    expect(await merchants.resolve(name: 'DELHAIZE SERBIA DOO BEOGRAD'), id);
  });

  test('ignore policy keeps receipt lines out of the catalog', () async {
    final id = await merchants.resolve(name: 'JGSP NOVI SAD');
    await merchants.update(id, policy: MerchantPolicy.ignore);
    final receipt = EqReceipt(
      id: 'bus',
      issuedAt: DateTime(2026, 8, 1),
      currency: 'RSD',
      receiptType: 'sale',
      merchantName: 'JGSP NOVI SAD',
      grandTotal: 80,
      items: const [EqItem(description: 'Bulevar Cara Lazara - Terminal /ком', quantity: 1, unitPrice: 80, totalPrice: 80)],
    );
    final saved = await receipts.upsertParsed(
      qrHash: 'jgsp:1',
      adapterId: 'rs_purs',
      rawQr: '{}',
      receipt: receipt,
      lastStatus: statusOk,
    );
    expect(saved.merchantId, id);
    final all = await merchants.listAll();
    await catalog.ingestFromReceipts([saved], all);
    expect(await catalog.listPositions(), isEmpty);
  });
}
