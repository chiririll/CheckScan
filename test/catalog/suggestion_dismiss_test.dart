import 'dart:io';

import 'package:checkscan/core/catalog/assist/assist_cluster.dart';
import 'package:checkscan/core/catalog/catalog_store.dart';
import 'package:checkscan/core/catalog/data/catalog_repository.dart';
import 'package:checkscan/core/catalog/model/catalog_position.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/state/app_state.dart';
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

  test('ignored items stay out of auto-clusters and appear as singletons', () {
    const milkA = CatalogPosition(id: 'a', displayName: 'Молоко Леб 2.5% 1.7л');
    const milkB = CatalogPosition(id: 'b', displayName: 'МОЛОКО ЛЕБ 2,5% 0,93Л');
    const milkC = CatalogPosition(id: 'c', displayName: 'Молоко Леб 0.5л');
    final afterOne = clusterUnassigned([milkA, milkB, milkC], ignoreIds: {'c'});
    expect(afterOne.where((group) => group.any((item) => item.id == 'c')).single, hasLength(1));
    expect(afterOne.firstWhere((group) => group.any((item) => item.id == 'a')).map((e) => e.id), containsAll(['a', 'b']));

    final allSolo = clusterUnassigned([milkA, milkB, milkC], ignoreIds: {'a', 'b', 'c'});
    expect(allSolo.every((group) => group.length == 1), isTrue);
  });

  late CheckScanDatabase database;
  late AppState state;

  setUp(() async {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_dismiss_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    final receipts = ReceiptRepository(database: database);
    state = AppState(
      repository: receipts,
      adapter: FakeNativeAdapter(),
      catalog: CatalogStore(repository: CatalogRepository(database: database)),
    );
    final saved = await receipts.upsertParsed(
      qrHash: 'h$_seq',
      adapterId: 'eq',
      rawQr: '{}',
      receipt: EqReceipt(
        id: 'r1',
        issuedAt: DateTime(2026, 8, 28),
        currency: 'RUB',
        receiptType: 'sale',
        merchantName: 'Пятёрочка',
        grandTotal: 210,
        items: const [
          EqItem(description: 'Молоко Леб 2.5% 1.7л', quantity: 1, unitPrice: 80, totalPrice: 80),
          EqItem(description: 'МОЛОКО ЛЕБ 2,5% 0,93Л', quantity: 1, unitPrice: 70, totalPrice: 70),
          EqItem(description: 'Молоко Леб 0.5л', quantity: 1, unitPrice: 60, totalPrice: 60),
        ],
      ),
      lastStatus: statusOk,
    );
    state.receipts = [saved];
    await state.catalog.ingest(state.receipts);
  });

  tearDown(() async {
    await database.close();
  });

  test('dismissed cluster member stays unassigned and is not regrouped', () async {
    expect(state.catalog.unassignedClusters.where((cluster) => cluster.positions.length > 1), hasLength(1));
    final extra = state.catalog.unassigned.firstWhere((item) => item.displayName.contains('0.5'));
    await state.catalog.dismissClusterItem(extra.id);
    expect(state.catalog.unassigned.map((item) => item.id), contains(extra.id));
    final clusters = state.catalog.unassignedClusters;
    expect(clusters.where((cluster) => cluster.positions.any((item) => item.id == extra.id)).single.positions, hasLength(1));
    expect(clusters.any((cluster) => cluster.positions.length == 2), isTrue);
    await state.catalog.reload();
    expect(state.catalog.suggestionIgnore.ignoresCluster(extra.id), isTrue);
  });

  test('dismissed similar candidate stays off that product and searchable', () async {
    final milk = await state.catalog.createProduct(name: 'Молоко');
    final candidate = state.catalog.similarCandidatesFor(milk.id).first;
    await state.catalog.dismissProductSuggestion(productId: milk.id, itemId: candidate.id);
    expect(state.catalog.similarCandidatesFor(milk.id).map((item) => item.id), isNot(contains(candidate.id)));
    expect(state.catalog.searchAttachableItems(milk.id, 'молоко').map((item) => item.id), contains(candidate.id));
    expect(state.catalog.positionById(candidate.id)?.productId, isNull);
  });

  testWidgets('cluster card X dismisses a suggested name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: CatalogPage(state: state),
      ),
    );
    await tester.pump();
    expect(find.text('Молоко Леб'), findsOneWidget);
    expect(find.byTooltip('Не предлагать'), findsWidgets);

    final extra = state.catalog.unassigned.firstWhere((item) => item.displayName.contains('0.5л'));
    expect(find.byKey(ValueKey<String>('dismiss-item-${extra.id}')), findsOneWidget);
    await tester.runAsync(() => state.catalog.dismissClusterItem(extra.id));
    await tester.pump();
    expect(state.catalog.suggestionIgnore.ignoresCluster(extra.id), isTrue);
    expect(find.byKey(ValueKey<String>('dismiss-item-${extra.id}')), findsNothing);
    expect(state.catalog.unassigned.map((item) => item.id), contains(extra.id));
    expect(state.catalog.unassignedClusters.where((cluster) => cluster.positions.length > 1), isNotEmpty);
  });
}
