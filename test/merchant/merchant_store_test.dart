import 'dart:io';

import 'package:checkscan/core/merchant/merchant.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/state/app_state.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../scan/fake_native_adapter.dart';

int _seq = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CheckScanDatabase database;
  late ReceiptRepository receipts;
  late AppState state;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_merchant_store_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    receipts = ReceiptRepository(database: database);
    state = AppState(repository: receipts, adapter: FakeNativeAdapter());
  });

  tearDown(() async {
    state.dispose();
    await database.close();
  });

  Future<String> saveReceipt() async {
    final saved = await receipts.upsertParsed(
      qrHash: 'shop:1',
      adapterId: 'test',
      rawQr: '{}',
      receipt: EqReceipt(
        id: 'r1',
        issuedAt: DateTime(2026, 8, 1),
        currency: 'RUB',
        receiptType: 'sale',
        merchantName: 'Магнит',
        grandTotal: 90,
        items: const [EqItem(description: 'Молоко 1л', quantity: 1, unitPrice: 90, totalPrice: 90)],
      ),
      lastStatus: statusOk,
    );
    return saved.merchantId!;
  }

  test('edits refresh the loaded list and notify the app state', () async {
    final merchantId = await saveReceipt();
    await state.load();
    var notified = 0;
    state.addListener(() => notified += 1);

    await state.merchants.update(merchantId, name: 'Магнит у дома');
    await state.merchants.addAlias(merchantId, taxId: '7700');

    final merchant = state.merchants.byId(merchantId)!;
    expect(merchant.name, 'Магнит у дома');
    expect(merchant.aliases.map((alias) => alias.taxId), contains('7700'));
    expect(notified, greaterThan(0));
    expect(state.merchants.byId(null), isNull);
  });

  test('ignore policy drops the merchant lines from purchases', () async {
    final merchantId = await saveReceipt();
    await state.load();
    final position = state.catalog.positions.single;
    await state.catalog.createProduct(name: 'Молоко', positionId: position.id);
    expect(state.catalog.purchases, hasLength(1));

    await state.setMerchantPolicy(merchantId, MerchantPolicy.ignore);

    expect(state.merchants.byId(merchantId)!.ignoresItems, isTrue);
    expect(state.catalog.purchases, isEmpty);
  });
}
