import 'dart:async';
import 'dart:io';

import 'package:checkscan/core/scan/native_adapter.dart';
import 'package:checkscan/core/state/app_state.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:checkscan/features/receipt_detail/receipt_page.dart';
import 'package:checkscan/l10n/app_localizations.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_native_adapter.dart';

/// Local parses answer at once; the network answer waits for [network].
class _SlowNetworkAdapter extends FakeNativeAdapter {
  final network = Completer<void>();

  @override
  Future<AdapterResult<AdapterResolve>> resolve(
    String rawQr, {
    String? hint,
    bool remote = false,
    bool wait = false,
    String? current,
  }) async {
    if (remote) {
      await network.future;
      nextReceipt = EqReceipt(
        id: 'ru-rich',
        issuedAt: DateTime(2026, 8, 28, 18, 42),
        currency: 'RUB',
        receiptType: 'sale',
        merchantName: 'Пятёрочка',
        grandTotal: 1247,
        items: const [EqItem(description: 'Хлеб', quantity: 1, unitPrice: 1247, totalPrice: 1247)],
      );
    }
    return super.resolve(rawQr, hint: hint, remote: remote, wait: wait, current: current);
  }
}

int _seq = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() => initializeDateFormatting('ru'));

  late CheckScanDatabase database;
  late _SlowNetworkAdapter adapter;
  late AppState state;

  setUp(() {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_bg_fetch_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    adapter = _SlowNetworkAdapter();
    state = AppState(repository: ReceiptRepository(database: database), adapter: adapter)..ready = true;
  });

  tearDown(() async {
    state.dispose();
    await database.close();
  });

  test('scan returns before the network answers and fills items afterwards', () async {
    final result = await state.processScan(FakeNativeAdapter.fnsQuery);
    final id = result.record!.id;

    expect(state.byId(id), isNotNull);
    expect(state.isFetching(id), isTrue);
    expect(state.byId(id)!.itemCount, 0);

    adapter.network.complete();
    await state.fetchDone(id);

    expect(state.isFetching(id), isFalse);
    expect(state.byId(id)!.itemCount, 1);
    expect(state.catalog.positions.single.displayName, 'Хлеб');
  });

  test('a complete receipt is not fetched again', () async {
    adapter.network.complete();
    final first = await state.processScan(FakeNativeAdapter.fnsQuery);
    await state.fetchDone(first.record!.id);

    final again = await state.processScan(FakeNativeAdapter.fnsQuery);
    expect(again.record!.itemCount, 1);
    expect(state.isFetching(again.record!.id), isTrue, reason: 'only the catalog sync runs');
    await state.fetchDone(again.record!.id);
  });

  testWidgets('receipt page shows a loader until the items arrive', (tester) async {
    final id = (await tester.runAsync(() => state.processScan(FakeNativeAdapter.fnsQuery)))!.record!.id;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ReceiptPage(state: state, receiptId: id),
      ),
    );
    expect(find.byKey(const ValueKey('receipt-fetching')), findsOneWidget);
    expect(find.text('Нет состава с сервера'), findsNothing);

    await tester.runAsync(() async {
      adapter.network.complete();
      await state.fetchDone(id);
    });
    await tester.pump();

    expect(find.byKey(const ValueKey('receipt-fetching')), findsNothing);
    expect(find.text('Хлеб'), findsOneWidget);
  });
}
