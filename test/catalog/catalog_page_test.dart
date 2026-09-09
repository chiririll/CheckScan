import 'dart:io';

import 'package:checkscan/core/app_state.dart';
import 'package:checkscan/core/catalog/catalog_repository.dart';
import 'package:checkscan/core/catalog/catalog_store.dart';
import 'package:checkscan/core/catalog/item_unit.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:checkscan/features/catalog/catalog_page.dart';
import 'package:checkscan/features/catalog/draft_product_page.dart';
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
      items: const [
        EqItem(description: 'Молоко Леб 2.5% 1.7л', quantity: 1, unitPrice: 80, totalPrice: 80),
        EqItem(description: 'МОЛОКО ЛЕБ 2,5% 0,93Л', quantity: 1, unitPrice: 70, totalPrice: 70),
        EqItem(description: 'Молоко Леб 0.5л', quantity: 1, unitPrice: 40, totalPrice: 40),
        EqItem(description: 'Молоко Леб 2л', quantity: 1, unitPrice: 90, totalPrice: 90),
      ],
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

  testWidgets('unassigned tab lists a cluster card instead of one row per position', (tester) async {
    await tester.pumpWidget(app(CatalogPage(state: state)));
    await tester.pump();
    expect(find.text('Молоко Леб'), findsOneWidget);
    final search = tester.widget<TextField>(find.byType(TextField));
    expect(search.decoration?.filled, isTrue);
    expect(search.decoration?.fillColor, Colors.white);
    expect(find.text('• Молоко Леб 2.5% 1.7л'), findsOneWidget);
    expect(find.text('• МОЛОКО ЛЕБ 2,5% 0,93Л'), findsOneWidget);
    expect(find.text('• Молоко Леб 0.5л'), findsOneWidget);
    expect(find.text('и ещё 1'), findsOneWidget);
    expect(find.text('В товар'), findsNothing);
    expect(find.text('Не разобрано'), findsWidgets);
    expect(find.text('Промпт'), findsNothing);
    expect(find.text('Вставить'), findsNothing);
    await tester.tap(find.byTooltip('Ещё'));
    await tester.pumpAndSettle();
    expect(find.text('Промпт'), findsOneWidget);
    expect(find.text('Вставить'), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Товары').first);
    await tester.pump();
    expect(find.byTooltip('Ещё'), findsNothing);
    expect(find.text('Промпт'), findsNothing);
    expect(find.text('Вставить'), findsNothing);
  });

  testWidgets('tapping a cluster opens a draft product that can drop a position', (tester) async {
    await tester.pumpWidget(app(CatalogPage(state: state)));
    await tester.pump();
    await tester.tap(find.text('Молоко Леб'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DraftProductPage), findsOneWidget);
    expect(find.text('Создать товар'), findsOneWidget);
    expect(find.descendant(of: find.byType(DraftProductPage), matching: find.byIcon(Icons.close)), findsNWidgets(4));
    await tester.tap(find.descendant(of: find.byType(DraftProductPage), matching: find.byIcon(Icons.close)).first);
    await tester.pump();
    expect(find.descendant(of: find.byType(DraftProductPage), matching: find.byIcon(Icons.close)), findsNWidgets(3));
  });

  test('createProductWithPositions assigns the cluster', () async {
    final ids = [for (final position in state.catalog.unassigned) position.id];
    final product = await state.catalog.createProductWithPositions(
      name: 'Молоко Леб',
      unit: ItemUnit.l,
      positionIds: ids,
    );
    expect(product.name, 'Молоко Леб');
    expect(product.unit, ItemUnit.l);
    expect(state.catalog.unassigned, isEmpty);
    expect(state.catalog.products.single.id, product.id);
  });
}
