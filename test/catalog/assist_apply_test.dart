import 'dart:io';

import 'package:checkscan/core/catalog/assist_apply.dart';
import 'package:checkscan/core/catalog/assist_draft.dart';
import 'package:checkscan/core/catalog/catalog_repository.dart';
import 'package:checkscan/core/catalog/item_unit.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _seq = 0;

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

  test('creates a product with category, unit and assigned positions', () async {
    await catalog.ingest(['Молоко Леб 2.5% 1.7л']);
    final position = (await catalog.listPositions()).single;
    final dairy = (await catalog.listCategories()).firstWhere((e) => e.name == '#dairyEggs');
    await applyAssistDraftToRepo(
      repository: catalog,
      products: const [],
      draft: AssistDraft(
        products: [
          AssistDraftProduct(
            name: 'Молоко',
            existingCategoryId: dairy.id,
            unit: ItemUnit.l,
            positions: [AssistDraftPosition(id: position.id, unitSize: 1.7, brand: 'Леб')],
          ),
        ],
      ),
    );
    final product = (await catalog.listProducts()).single;
    expect(product.name, 'Молоко');
    expect(product.categoryId, dairy.id);
    expect(product.unit, ItemUnit.l);
    expect((await catalog.listPositions()).single.productId, product.id);
    expect((await catalog.listPositions()).single.unitSize, 1.7);
    expect((await catalog.listPositions()).single.brand, 'Леб');
  });

  test('does not overwrite unit or name of an existing product', () async {
    await catalog.ingest(['Молоко Леб 2.5% 1.7л']);
    final position = (await catalog.listPositions()).single;
    final existing = await catalog.createProduct(name: 'Молоко', unit: ItemUnit.piece);
    await applyAssistDraftToRepo(
      repository: catalog,
      products: [existing],
      draft: AssistDraft(
        products: [
          AssistDraftProduct(
            name: 'Milk',
            existingProductId: existing.id,
            unit: ItemUnit.l,
            positions: [AssistDraftPosition(id: position.id)],
          ),
        ],
      ),
    );
    final product = (await catalog.listProducts()).single;
    expect(product.name, 'Молоко');
    expect(product.unit, ItemUnit.piece);
    expect((await catalog.listPositions()).single.productId, existing.id);
  });

  test('skips a removed new category and a removed product', () async {
    await catalog.ingest(['Молоко Леб 2.5% 1.7л', 'Пельмени 400г']);
    final positions = await catalog.listPositions();
    final milk = positions.firstWhere((e) => e.displayName.startsWith('Молоко'));
    var draft = AssistDraft(
      newCategories: const [AssistNewCategory(key: 'заморозка', name: 'Заморозка')],
      products: [
        AssistDraftProduct(
          name: 'Пельмени',
          newCategoryKey: 'заморозка',
          positions: [AssistDraftPosition(id: positions.firstWhere((e) => e.displayName.startsWith('Пельмени')).id)],
        ),
        AssistDraftProduct(name: 'Молоко', unit: ItemUnit.l, positions: [AssistDraftPosition(id: milk.id)]),
      ],
    );
    draft = draft.withoutCategory('заморозка').withoutProduct(0);
    await applyAssistDraftToRepo(repository: catalog, products: const [], draft: draft);
    expect((await catalog.listCategories()).any((e) => e.name == 'Заморозка'), isFalse);
    expect((await catalog.listProducts()).single.name, 'Молоко');
  });
}
