import 'dart:io';

import 'package:checkscan/core/app_state.dart';
import 'package:checkscan/core/catalog/catalog_repository.dart';
import 'package:checkscan/core/catalog/catalog_store.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:checkscan/features/catalog/catalog_page.dart';
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

  setUp(() async {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_catalog_ui_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    final receipts = ReceiptRepository(database: database);
    state = AppState(
      repository: receipts,
      adapter: FakeNativeAdapter(),
      catalog: CatalogStore(repository: CatalogRepository(database: database)),
    );
    final receipt = EqReceipt(
      id: 'r1',
      issuedAt: DateTime(2026, 8, 28),
      currency: 'RUB',
      receiptType: 'sale',
      merchantName: 'Пятёрочка',
      grandTotal: 80,
      items: const [EqItem(description: 'Молоко 1,5л', quantity: 1, unitPrice: 80, totalPrice: 80)],
    );
    final saved = await receipts.upsertParsed(
      qrHash: 'h',
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

  testWidgets('unassigned tab lists ingested positions with parsed unit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: CatalogPage(state: state),
      ),
    );
    await tester.pump();
    expect(find.text('Молоко 1,5л'), findsOneWidget);
    expect(find.text('1.5 л'), findsOneWidget);
    expect(find.text('В товар'), findsOneWidget);
  });
}
