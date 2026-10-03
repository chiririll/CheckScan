import 'dart:io';

import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:receipt_model/receipt_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _dbSeq = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ReceiptRepository repository;

  setUp(() {
    _dbSeq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_repo_$_dbSeq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    repository = ReceiptRepository(resolveDbPath: () async => path);
  });

  tearDown(() async {
    await repository.close();
  });

  test('findByHash returns the inserted receipt', () async {
    final receipt = Receipt(
      id: 'r1',
      issuedAt: DateTime(2026, 8, 28, 18, 42),
      currency: 'RUB',
      type: 'sale',
      merchantName: 'Магнит',
      total: 9900,
      items: const [ReceiptItem(name: 'Хлеб', quantity: 1, price: 9900, sum: 9900)],
    );
    await repository.upsertParsed(
      qrHash: 'eq_payload:r1',
      adapterId: 'eq_payload',
      rawQr: '{}',
      receipt: receipt,
      lastStatus: statusOk,
    );

    final found = await repository.findByHash('eq_payload:r1');
    expect(found, isNotNull);
    expect(found!.merchantName, 'Магнит');
    expect(found.itemCount, 1);
    expect(found.receipt.items.single.name, 'Хлеб');
  });

  test('listAll is newest first', () async {
    await repository.upsertParsed(
      qrHash: 'a:1',
      adapterId: 'eq_payload',
      rawQr: '1',
      receipt: Receipt(
        id: 'old',
        issuedAt: DateTime(2026, 1, 1),
        currency: 'RUB',
        type: 'sale',
        total: 1000,
      ),
      lastStatus: statusOk,
    );
    await repository.upsertParsed(
      qrHash: 'a:2',
      adapterId: 'eq_payload',
      rawQr: '2',
      receipt: Receipt(
        id: 'new',
        issuedAt: DateTime(2026, 8, 28),
        currency: 'RUB',
        type: 'sale',
        total: 2000,
      ),
      lastStatus: statusOk,
    );

    final list = await repository.listAll();
    expect(list.map((e) => e.qrHash), ['a:2', 'a:1']);
  });

  test('deleteById removes the receipt', () async {
    final saved = await repository.upsertParsed(
      qrHash: 'a:1',
      adapterId: 'eq_payload',
      rawQr: '1',
      receipt: Receipt(
        id: 'gone',
        issuedAt: DateTime(2026, 8, 28),
        currency: 'RUB',
        type: 'sale',
        total: 1000,
      ),
      lastStatus: statusOk,
    );

    await repository.deleteById(saved.id);

    expect(await repository.listAll(), isEmpty);
  });
}
