import 'dart:io';

import 'package:eq_models/eq_models.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
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

  test('findByHash returns the inserted receipt', () async {
    final receipt = EqReceipt(
      id: 'r1',
      issuedAt: DateTime(2026, 8, 28, 18, 42),
      currency: 'RUB',
      receiptType: 'sale',
      merchantName: 'Магнит',
      grandTotal: 99,
      items: const [EqItem(description: 'Хлеб', quantity: 1, unitPrice: 99, totalPrice: 99)],
    );
    await repository.insertParsed(
      qrHash: 'eq_payload:r1',
      adapterId: 'eq_payload',
      rawQr: '{}',
      receipt: receipt,
      status: ReceiptStatus.ok,
    );

    final found = await repository.findByHash('eq_payload:r1');
    expect(found, isNotNull);
    expect(found!.merchantName, 'Магнит');
    expect(found.itemCount, 1);
    expect(found.receipt.items.single.description, 'Хлеб');
  });

  test('listAll is newest first', () async {
    await repository.insertParsed(
      qrHash: 'a:1',
      adapterId: 'eq_payload',
      rawQr: '1',
      receipt: EqReceipt(
        id: 'old',
        issuedAt: DateTime(2026, 1, 1),
        currency: 'RUB',
        receiptType: 'sale',
        grandTotal: 10,
      ),
      status: ReceiptStatus.ok,
    );
    await repository.insertParsed(
      qrHash: 'a:2',
      adapterId: 'eq_payload',
      rawQr: '2',
      receipt: EqReceipt(
        id: 'new',
        issuedAt: DateTime(2026, 8, 28),
        currency: 'RUB',
        receiptType: 'sale',
        grandTotal: 20,
      ),
      status: ReceiptStatus.ok,
    );

    final list = await repository.listAll();
    expect(list.map((e) => e.id), ['new', 'old']);
  });

  test('deleteById removes the receipt', () async {
    await repository.insertParsed(
      qrHash: 'a:1',
      adapterId: 'eq_payload',
      rawQr: '1',
      receipt: EqReceipt(
        id: 'gone',
        issuedAt: DateTime(2026, 8, 28),
        currency: 'RUB',
        receiptType: 'sale',
        grandTotal: 10,
      ),
      status: ReceiptStatus.ok,
    );

    await repository.deleteById('gone');

    expect(await repository.findById('gone'), isNull);
    expect(await repository.listAll(), isEmpty);
  });
}
