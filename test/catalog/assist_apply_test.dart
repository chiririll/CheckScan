import 'dart:io';

import 'package:checkscan/core/catalog/assist/assist_apply.dart';
import 'package:checkscan/core/catalog/assist/assist_draft.dart';
import 'package:checkscan/core/catalog/data/catalog_repository.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _seq = 0;

AssistMatchedPosition _hit(String id, String name) {
  return AssistMatchedPosition(positionId: id, displayName: name, confidence: 1, rawLine: name);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CheckScanDatabase database;
  late CatalogRepository catalog;

  setUp(() {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_assist_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    catalog = CatalogRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('apply creates products and assigns matched positions', () async {
    await catalog.ingest(['Молоко Леб 2.5% 1.7л', 'Хлеб дарницкий']);
    final positions = await catalog.listPositions();
    final milk = positions.firstWhere((item) => item.displayName.startsWith('Молоко'));
    final bread = positions.firstWhere((item) => item.displayName.startsWith('Хлеб'));
    await applyAssistDraftToRepo(
      repository: catalog,
      draft: AssistDraft(
        products: [
          AssistDraftProduct(name: 'Молоко', positions: [_hit(milk.id, milk.displayName)]),
          AssistDraftProduct(name: 'Хлеб', positions: [_hit(bread.id, bread.displayName)]),
        ],
      ),
    );
    final products = await catalog.listProducts();
    expect(products.map((item) => item.name), containsAll(['Молоко', 'Хлеб']));
    final assigned = {for (final item in await catalog.listPositions()) item.id: item.productId};
    expect(assigned[milk.id], isNotNull);
    expect(assigned[bread.id], isNotNull);
    expect(assigned[milk.id], isNot(assigned[bread.id]));
  });

  test('cancel-equivalent empty draft does not create products', () async {
    await catalog.ingest(['Молоко Леб 2.5% 1.7л']);
    final position = (await catalog.listPositions()).single;
    var draft = AssistDraft(
      products: [AssistDraftProduct(name: 'Молоко', positions: [_hit(position.id, position.displayName)])],
    );
    draft = draft.withoutProduct(0);
    await applyAssistDraftToRepo(repository: catalog, draft: draft);
    expect(await catalog.listProducts(), isEmpty);
    expect((await catalog.listPositions()).single.productId, isNull);
  });

  test('removed position is not assigned', () async {
    await catalog.ingest(['Молоко Леб 2.5% 1.7л', 'МОЛОКО ЛЕБ 0.93Л']);
    final positions = await catalog.listPositions();
    var draft = AssistDraft(
      products: [
        AssistDraftProduct(
          name: 'Молоко',
          positions: [for (final item in positions) _hit(item.id, item.displayName)],
        ),
      ],
    );
    draft = draft.withoutPosition(0, positions.first.id);
    await applyAssistDraftToRepo(repository: catalog, draft: draft);
    expect((await catalog.listProducts()).single.name, 'Молоко');
    final left = await catalog.listPositions();
    expect(left.firstWhere((item) => item.id == positions.first.id).productId, isNull);
    expect(left.firstWhere((item) => item.id == positions.last.id).productId, isNotNull);
  });
}
