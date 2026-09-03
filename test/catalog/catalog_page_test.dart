import 'dart:io';

import 'package:checkscan/core/app_state.dart';
import 'package:checkscan/core/catalog/catalog_position.dart';
import 'package:checkscan/core/catalog/catalog_repository.dart';
import 'package:checkscan/core/catalog/catalog_store.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:checkscan/features/catalog/catalog_page.dart';
import 'package:checkscan/features/catalog/merge_group_page.dart';
import 'package:checkscan/l10n/app_localizations.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../scan/fake_native_adapter.dart';

int _seq = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CheckScanDatabase database;
  late AppState state;
  late CatalogRepository catalog;

  setUp(() async {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_catalog_ui_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    final receipts = ReceiptRepository(database: database);
    catalog = CatalogRepository(database: database);
    state = AppState(
      repository: receipts,
      adapter: FakeNativeAdapter(),
      catalog: CatalogStore(repository: catalog),
    );
    final receipt = EqReceipt(
      id: 'r1',
      issuedAt: DateTime(2026, 8, 28),
      currency: 'RUB',
      receiptType: 'sale',
      merchantName: 'Пятёрочка',
      grandTotal: 80,
      items: const [EqItem(description: 'Молоко Леб 2.5% 1.7л', quantity: 1, unitPrice: 80, totalPrice: 80)],
    );
    final saved = await receipts.upsertParsed(
      qrHash: 'h$_seq',
      adapterId: 'eq',
      rawQr: '{}',
      receipt: receipt,
      lastStatus: statusOk,
    );
    state.receipts = [saved];
    await state.catalog.ingest(state.receipts);
  });

  tearDown(() async {
    await database.close();
  });

  Widget app(Widget home) {
    return MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );
  }

  testWidgets('unassigned tab lists ingested positions with parsed unit', (tester) async {
    await tester.pumpWidget(app(CatalogPage(state: state)));
    await tester.pump();
    expect(find.text('Молоко Леб 2.5% 1.7л'), findsOneWidget);
    expect(find.text('1.7 л'), findsOneWidget);
    expect(find.text('В товар'), findsOneWidget);
    expect(find.text('Каталог'), findsWidgets);
    expect(find.text('Промпт'), findsOneWidget);
    expect(find.text('Вставить'), findsOneWidget);
    await tester.tap(find.text('Товары').first);
    await tester.pump();
    expect(find.text('Промпт'), findsNothing);
    expect(find.text('Вставить'), findsNothing);
  });

  testWidgets('merge group lists cluster peers and can drop a member', (tester) async {
    final target = state.catalog.unassigned.single;
    const peer = CatalogPosition(id: 'peer', displayName: 'МОЛОКО ЛЕБ 2,5% 0,93Л', unitSize: 0.93);
    await tester.pumpWidget(app(MergeGroupPage(state: state, target: target, peers: const [peer])));
    await tester.pump();
    expect(find.text('Объединить'), findsWidgets);
    expect(find.text('Молоко Леб 2.5% 1.7л'), findsOneWidget);
    expect(find.text('МОЛОКО ЛЕБ 2,5% 0,93Л'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('МОЛОКО ЛЕБ 2,5% 0,93Л'), findsNothing);
  });
}
