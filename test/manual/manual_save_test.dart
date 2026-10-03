import 'dart:io';

import 'package:checkscan/core/manual/manual_receipt.dart';
import 'package:checkscan/core/state/app_state.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:receipt_model/receipt_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../scan/fake_native_adapter.dart';
import '../support/receipt_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ReceiptRepository repository;
  late AppState state;

  setUp(() {
    final path = p.join(Directory.systemTemp.path, 'checkscan_manual_${DateTime.now().microsecondsSinceEpoch}.db');
    repository = ReceiptRepository(resolveDbPath: () async => path);
    state = AppState(repository: repository, adapter: FakeNativeAdapter());
  });

  tearDown(() async {
    await repository.close();
  });

  Receipt receipt({String? merchant = 'Рынок', int total = 15000}) {
    return testReceipt(id: 'm1', merchantName: merchant, total: total);
  }

  test('saves a manual receipt that never needs a fetch', () async {
    final record = await state.saveManual(receipt(), label: 'Вручную');

    expect(record.isManual, isTrue);
    expect(record.canRetry, isFalse);
    expect(record.missingRemoteItems, isFalse);
    expect(record.providerLabel, 'Вручную');
    expect(record.merchantId, isNotNull);
    expect(state.receipts.single.id, record.id);
    expect(await repository.findByHash('$manualAdapterId:m1'), isNotNull);
  });

  test('editing keeps id and scan time, and updates the amount', () async {
    final first = await state.saveManual(receipt(), label: 'Вручную');
    final edited = await state.saveManual(receipt(total: 20000), label: 'Вручную', existing: first);

    expect(edited.id, first.id);
    expect(edited.scannedAt, first.scannedAt);
    expect(edited.total, 20000);
    expect((await repository.listAll()), hasLength(1));
  });

  test('clearing the merchant on edit drops the merchant link', () async {
    final first = await state.saveManual(receipt(), label: 'Вручную');
    final edited = await state.saveManual(receipt(merchant: null), label: 'Вручную', existing: first);

    expect(first.merchantId, isNotNull);
    expect(edited.merchantId, isNull);
  });
}
