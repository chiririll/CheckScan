import 'dart:io';

import 'package:checkscan/core/catalog/catalog_store.dart';
import 'package:checkscan/core/catalog/data/catalog_repository.dart';
import 'package:checkscan/core/catalog/model/purchase.dart';
import 'package:checkscan/core/catalog/product_receipts.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/state/app_state.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:checkscan/features/catalog/product_page.dart';
import 'package:checkscan/features/catalog/product_receipts_page.dart';
import 'package:checkscan/features/receipt_detail/receipt_page.dart';
import 'package:checkscan/l10n/app_localizations.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../scan/fake_native_adapter.dart';

int _seq = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  setUpAll(() => initializeDateFormatting('ru'));

  test('returns unique receipts that have a purchase for the product, newest first', () {
    final found = receiptsContainingProduct(
      productId: 'milk',
      purchases: [
        _purchase(id: 'p1', checkId: 'old', productId: 'milk', at: DateTime(2026, 8, 1)),
        _purchase(id: 'p2', checkId: 'new', productId: 'milk', at: DateTime(2026, 8, 8)),
        _purchase(id: 'p3', checkId: 'new', productId: 'milk', at: DateTime(2026, 8, 8)),
        _purchase(id: 'p4', checkId: 'other', productId: 'bread', at: DateTime(2026, 8, 9)),
      ],
      receipts: [
        _receipt(id: 'old', merchant: 'Магнит', at: DateTime(2026, 8, 1)),
        _receipt(id: 'new', merchant: 'Пятёрочка', at: DateTime(2026, 8, 8)),
        _receipt(id: 'other', merchant: 'Лента', at: DateTime(2026, 8, 9)),
      ],
    );
    expect(found.map((e) => e.id), ['new', 'old']);
  });

  test('skips unmatched names that never produced a purchase', () {
    expect(
      receiptsContainingProduct(
        productId: 'milk',
        purchases: const [],
        receipts: [_receipt(id: 'r1', merchant: 'Магнит', at: DateTime(2026, 8, 1))],
      ),
      isEmpty,
    );
  });

  late CheckScanDatabase database;
  late AppState state;

  setUp(() async {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_product_receipts_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    final receipts = ReceiptRepository(database: database);
    state = AppState(
      repository: receipts,
      adapter: FakeNativeAdapter(),
      catalog: CatalogStore(repository: CatalogRepository(database: database)),
    );
    final first = await receipts.upsertParsed(
      qrHash: 'h1$_seq',
      adapterId: 'eq',
      rawQr: '{}',
      receipt: EqReceipt(
        id: 'r1',
        issuedAt: DateTime(2026, 8, 1),
        currency: 'RUB',
        receiptType: 'sale',
        merchantName: 'Магнит',
        grandTotal: 80,
        items: const [EqItem(description: 'Молоко 1 л', quantity: 1, unitPrice: 80, totalPrice: 80)],
      ),
      lastStatus: statusOk,
    );
    final second = await receipts.upsertParsed(
      qrHash: 'h2$_seq',
      adapterId: 'eq',
      rawQr: '{}',
      receipt: EqReceipt(
        id: 'r2',
        issuedAt: DateTime(2026, 8, 8),
        currency: 'RUB',
        receiptType: 'sale',
        merchantName: 'Пятёрочка',
        grandTotal: 90,
        items: const [EqItem(description: 'Молоко 1 л', quantity: 1, unitPrice: 90, totalPrice: 90)],
      ),
      lastStatus: statusOk,
    );
    state.receipts = [first, second];
    await state.catalog.ingest(state.receipts);
    final position = state.catalog.unassigned.single;
    await state.catalog.createProductWithPositions(name: 'Молоко', positionIds: [position.id]);
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('product menu and tile open receipts that contain this product', (tester) async {
    final product = state.catalog.products.single;
    await tester.pumpWidget(_app(ProductPage(state: state, productId: product.id)));
    await tester.pump();

    expect(find.text('Молоко'), findsWidgets);
    await tester.tap(find.text('В чеках').first);
    await tester.pumpAndSettle();
    expect(find.byType(ProductReceiptsPage), findsOneWidget);
    expect(find.text('Пятёрочка'), findsOneWidget);
    expect(find.text('Магнит'), findsOneWidget);

    await tester.tap(find.text('Пятёрочка'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptPage), findsOneWidget);
  });

  testWidgets('product receipts empty state when none are linked', (tester) async {
    await tester.pumpWidget(_app(ProductReceiptsPage(state: state, productId: 'missing')));
    await tester.pump();
    expect(find.text('Пока нет чеков'), findsOneWidget);
    expect(find.text('Этот товар ещё не встречался в сохранённых чеках.'), findsOneWidget);
  });
}

Widget _app(Widget home) {
  return MaterialApp(
    locale: const Locale('ru'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}

Purchase _purchase({required String id, required String checkId, required String productId, required DateTime at}) {
  return Purchase(
    id: id,
    checkId: checkId,
    productId: productId,
    quantity: 1,
    unitPrice: 80,
    total: 80,
    currency: 'RUB',
    issuedAt: at,
  );
}

ReceiptRecord _receipt({required String id, required String merchant, required DateTime at}) {
  return ReceiptRecord(
    id: id,
    qrHash: 'h:$id',
    adapterId: 'eq',
    status: ReceiptStatus.ok,
    issuedAt: at,
    merchantName: merchant,
    grandTotal: 80,
    currency: 'RUB',
    itemCount: 1,
    payload: '{}',
    scannedAt: at,
    rawQr: id,
  );
}
