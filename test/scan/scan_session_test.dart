import 'dart:io';

import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/scan/scan_session.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_providers_backend.dart';

int _dbSeq = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ReceiptRepository repository;
  late ScanSession session;

  setUp(() {
    _dbSeq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_session_$_dbSeq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    repository = ReceiptRepository(resolveDbPath: () async => path);
    session = ScanSession(repository: repository, backend: FakeProvidersBackend());
  });

  const eqJson =
      '{"eq_version":"1.0.0","receipt":{"id":"550e8400-e29b-41d4-a716-446655440000","issued_at":"2026-08-28T18:42:00+03:00","currency":"RUB","receipt_type":"sale","merchant":{"name":"Пятёрочка"},"items":[{"description":"Молоко 1 л","quantity":2,"unit_price":89,"total_price":178}],"totals":{"grand_total":1247}}}';

  test('unknown format is not saved', () async {
    final result = await session.process('not-a-receipt');
    expect(result.unknown, isTrue);
    expect(await repository.listAll(), isEmpty);
  });

  test('eQ scan saves items as ok', () async {
    final result = await session.process(eqJson);
    expect(result.unknown, isFalse);
    expect(result.record!.status, ReceiptStatus.ok);
    expect(result.record!.itemCount, 1);
    expect(result.record!.merchantName, 'Пятёрочка');
  });

  test('FNS scan without items is incomplete until the provider says otherwise', () async {
    final result = await session.process(FakeProvidersBackend.fnsQuery);
    expect(result.record!.status, ReceiptStatus.incomplete);
    expect(result.record!.grandTotal, 1247);
    expect(result.record!.itemCount, 0);
    expect(result.record!.qrHash, 'ru_fns:${FakeProvidersBackend.fnsHash}');
  });

  test('duplicate hash opens existing row without a second insert', () async {
    final first = await session.process(FakeProvidersBackend.fnsQuery);
    final second = await session.process(FakeProvidersBackend.fnsQuery);
    expect(second.record!.id, first.record!.id);
    expect(await repository.listAll(), hasLength(1));
  });

  test('parse error still inserts status=error', () async {
    session = ScanSession(
      repository: repository,
      backend: FakeProvidersBackend(throwOnResolve: true),
    );
    final result = await session.process('boom');
    expect(result.unknown, isFalse);
    expect(result.record!.status, ReceiptStatus.error);
    expect(result.record!.qrHash, 'boom:h');
  });

  test('refresh keeps the stored receipt when the new payload is not richer', () async {
    final saved = await session.process(FakeProvidersBackend.fnsQuery);
    final payload = saved.record!.payload;
    final updated = await session.refresh(saved.record!);
    expect(updated!.payload, payload);
    expect(updated.status, ReceiptStatus.incomplete);
    expect(await repository.listAll(), hasLength(1));
  });

  test('refresh replaces the receipt when the new payload is richer', () async {
    final backend = FakeProvidersBackend();
    session = ScanSession(repository: repository, backend: backend);
    final saved = await session.process(FakeProvidersBackend.fnsQuery);
    backend.nextReceipt = EqReceipt(
      id: 'ru-rich',
      issuedAt: DateTime(2026, 8, 28, 18, 42),
      currency: 'RUB',
      receiptType: 'sale',
      merchantName: 'Пятёрочка',
      grandTotal: 1247,
      items: const [EqItem(description: 'Хлеб', quantity: 1, unitPrice: 1247, totalPrice: 1247)],
    );
    final updated = await session.refresh(saved.record!);
    expect(updated!.itemCount, 1);
    expect(updated.merchantName, 'Пятёрочка');
    expect(updated.status, ReceiptStatus.ok);
  });

  test('refreshPending walks error receipts', () async {
    session = ScanSession(
      repository: repository,
      backend: FakeProvidersBackend(throwOnResolve: true),
    );
    await session.process('boom');
    session = ScanSession(repository: repository, backend: FakeProvidersBackend());
    final n = await session.refreshPending();
    expect(n, 1);
    expect(await repository.listAll(), hasLength(1));
  });

  test('stores provider label from the backend', () async {
    final result = await session.process(FakeProvidersBackend.fnsQuery);
    expect(result.record!.providerLabel, 'RU');
  });

  test('onMatched fires after a format is recognized', () async {
    var called = false;
    await session.process(FakeProvidersBackend.fnsQuery, onMatched: () => called = true);
    expect(called, isTrue);
  });
}
