import 'dart:io';

import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/scan/scan_session.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_native_adapter.dart';

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
    session = ScanSession(repository: repository, adapter: FakeNativeAdapter());
  });

  tearDown(() async {
    await repository.close();
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
    expect(result.record!.status, ReceiptStatus.ok);
    expect(result.record!.itemCount, 1);
    expect(result.record!.lastStatus, statusOk);
  });

  test('FNS scan without items is incomplete', () async {
    final result = await session.process(FakeNativeAdapter.fnsQuery);
    expect(result.record!.status, ReceiptStatus.incomplete);
    expect(result.record!.grandTotal, 1247);
    expect(result.record!.lastStatus, statusIncomplete);
  });

  test('duplicate complete hash opens existing without resolve overwrite', () async {
    final first = await session.process(eqJson);
    final second = await session.process(eqJson);
    expect(second.record!.id, first.record!.id);
    expect(await repository.listAll(), hasLength(1));
  });

  test('resolve failure does not insert a stub', () async {
    session = ScanSession(
      repository: repository,
      adapter: FakeNativeAdapter(failResolve: true),
    );
    final result = await session.process('boom');
    expect(result.record, isNull);
    expect(result.status, statusParseError);
    expect(await repository.listAll(), isEmpty);
  });

  test('re-scan retries incomplete receipt', () async {
    final first = await session.process(FakeNativeAdapter.fnsQuery);
    final adapter = FakeNativeAdapter();
    adapter.nextReceipt = EqReceipt(
      id: 'ru-rich',
      issuedAt: DateTime(2026, 8, 28, 18, 42),
      currency: 'RUB',
      receiptType: 'sale',
      merchantName: 'Пятёрочка',
      grandTotal: 1247,
      items: const [EqItem(description: 'Хлеб', quantity: 1, unitPrice: 1247, totalPrice: 1247)],
    );
    session = ScanSession(repository: repository, adapter: adapter);
    final second = await session.process(FakeNativeAdapter.fnsQuery);
    expect(second.record!.id, first.record!.id);
    expect(second.record!.itemCount, 1);
    expect(second.record!.status, ReceiptStatus.ok);
  });

  test('refresh replaces when adapter returns a richer receipt', () async {
    final adapter = FakeNativeAdapter();
    session = ScanSession(repository: repository, adapter: adapter);
    final saved = await session.process(FakeNativeAdapter.fnsQuery);
    adapter.nextReceipt = EqReceipt(
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
    expect(updated.status, ReceiptStatus.ok);
  });

  test('refreshPending walks retryable receipts', () async {
    await session.process(FakeNativeAdapter.fnsQuery);
    final adapter = FakeNativeAdapter();
    adapter.nextReceipt = EqReceipt(
      id: 'ru-rich',
      issuedAt: DateTime(2026, 8, 28),
      currency: 'RUB',
      receiptType: 'sale',
      grandTotal: 1247,
      items: const [EqItem(description: 'Хлеб', quantity: 1, unitPrice: 1247, totalPrice: 1247)],
    );
    session = ScanSession(repository: repository, adapter: adapter);
    expect(await session.refreshPending(), 1);
  });

  test('stores provider label from the adapter', () async {
    final result = await session.process(FakeNativeAdapter.fnsQuery);
    expect(result.record!.providerLabel, 'RU');
  });

  test('onMatched fires after a format is recognized', () async {
    var called = false;
    await session.process(FakeNativeAdapter.fnsQuery, onMatched: () => called = true);
    expect(called, isTrue);
  });
}
