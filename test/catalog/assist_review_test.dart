import 'dart:io';

import 'package:checkscan/core/app_state.dart';
import 'package:checkscan/core/catalog/assist_draft.dart';
import 'package:checkscan/core/catalog/catalog_repository.dart';
import 'package:checkscan/core/catalog/catalog_store.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:checkscan/features/catalog/assist_review_page.dart';
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
    final path = p.join(Directory.systemTemp.path, 'checkscan_assist_ui_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    final receipts = ReceiptRepository(database: database);
    final catalog = CatalogRepository(database: database);
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
        EqItem(description: 'Хлеб дарницкий', quantity: 1, unitPrice: 40, totalPrice: 40),
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

  AssistDraft draft() {
    final milk = state.catalog.unassigned.firstWhere((item) => item.displayName.startsWith('Молоко'));
    return AssistDraft(
      products: [
        AssistDraftProduct(
          name: 'Молоко',
          positions: [
            AssistMatchedPosition(
              positionId: milk.id,
              displayName: milk.displayName,
              confidence: 0.9,
              rawLine: milk.displayName,
            ),
          ],
        ),
      ],
      unmatched: const [AssistUnmatchedLine(raw: 'неизвестная строка')],
    );
  }

  Widget app() {
    return MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => AssistReviewPage(state: state, draft: draft())),
              );
            },
            child: const Text('open-review'),
          ),
        ),
      ),
    );
  }

  Future<void> openReview(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('open-review'));
    await tester.pumpAndSettle();
  }

  testWidgets('apply creates products from the review', (tester) async {
    final pending = draft();
    await openReview(tester);
    expect(find.text('Молоко'), findsOneWidget);
    expect(find.text('Не удалось сопоставить'), findsOneWidget);
    expect(find.text('неизвестная строка'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Применить')).onPressed, isNotNull);
    await tester.runAsync(() => state.catalog.applyAssistDraft(pending));
    expect(state.catalog.products.single.name, 'Молоко');
    expect(state.catalog.unassigned.any((item) => item.displayName.startsWith('Молоко')), isFalse);
  });

  testWidgets('cancel leaves the catalog unchanged', (tester) async {
    await openReview(tester);
    expect(find.text('Применить'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(state.catalog.products, isEmpty);
    expect(state.catalog.unassigned, hasLength(2));
  });
}
