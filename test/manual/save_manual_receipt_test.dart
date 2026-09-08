import 'dart:io';

import 'package:checkscan/core/app_state.dart';
import 'package:checkscan/core/catalog/item_unit.dart';
import 'package:checkscan/core/manual/manual_receipt.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveManualReceipt writes provider manual and links the product', () async {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_manual_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    final repository = ReceiptRepository(resolveDbPath: () async => path);
    addTearDown(() async {
      await repository.close();
      if (file.existsSync()) file.deleteSync();
    });

    final state = AppState(repository: repository, adapter: FakeNativeAdapter());
    await state.load();
    final product = await state.catalog.createProduct(name: 'Молоко', unit: ItemUnit.l);

    final saved = await state.saveManualReceipt(
      merchantName: 'Рынок',
      issuedAt: DateTime(2026, 9, 8, 11),
      lines: [
        ManualLine(productId: product.id, description: 'Молоко', quantity: 2, unitPrice: 80),
      ],
    );

    expect(saved.adapterId, manualProviderId);
    expect(saved.rawQr, isEmpty);
    expect(saved.qrHash, startsWith('manual:'));
    expect(saved.merchantName, 'Рынок');
    expect(saved.grandTotal, 160);
    expect(saved.receipt.items.single.description, 'Молоко');
    expect(state.catalog.resolver.resolve('Молоко')?.product?.id, product.id);
    expect(state.catalog.purchases, isNotEmpty);
    expect(state.catalog.purchases.single.productId, product.id);
    expect(state.catalog.purchases.single.quantity, 2);
  });
}
