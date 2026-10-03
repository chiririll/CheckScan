import 'dart:io';

import 'package:checkscan/core/catalog/data/catalog_repository.dart';
import 'package:checkscan/core/catalog/model/item_unit.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:eq_models/eq_models.dart';
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
    final path = p.join(Directory.systemTemp.path, 'checkscan_catalog_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    catalog = CatalogRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('seeds categories on a fresh database', () async {
    final categories = await catalog.listCategories();
    expect(categories.map((e) => e.name), containsAll(['#dairyEggs', '#other', '#products']));
    expect(categories.every((e) => e.isSeed), isTrue);
    final products = categories.firstWhere((e) => e.name == '#products');
    final dairy = categories.firstWhere((e) => e.name == '#dairyEggs');
    expect(products.parentId, isNull);
    expect(dairy.parentId, products.id);
  });

  test('ingest creates a position with parsed size only once', () async {
    await catalog.ingest(['Молоко Леб 2.5% 1.7л', 'Молоко Леб 2.5% 1.7л']);
    final positions = await catalog.listPositions();
    expect(positions, hasLength(1));
    expect(positions.single.unitSize, 1.7);
    expect(positions.single.aliases, ['Молоко Леб 2.5% 1.7л']);
  });

  test('does not overwrite size when the same raw name is ingested again', () async {
    await catalog.ingest(['Хлеб']);
    await catalog.updatePosition((await catalog.listPositions()).single.id, unitSize: 2);
    await catalog.ingest(['Хлеб', 'Батон']);
    final positions = await catalog.listPositions();
    final bread = positions.firstWhere((e) => e.displayName == 'Хлеб');
    expect(bread.unitSize, 2);
    expect(positions.where((e) => e.displayName == 'Батон').single.unitSize, isNull);
  });

  test('merge moves aliases and copies size when target is empty', () async {
    await catalog.ingest(['Молоко', 'МОЛОКО 1.5Л']);
    final positions = await catalog.listPositions();
    final source = positions.firstWhere((e) => e.displayName == 'МОЛОКО 1.5Л');
    final target = positions.firstWhere((e) => e.displayName == 'Молоко');
    expect(target.unitSize, isNull);
    await catalog.mergePositions(sourceId: source.id, targetId: target.id);
    final after = await catalog.listPositions();
    expect(after, hasLength(1));
    expect(after.single.aliases, containsAll(['Молоко', 'МОЛОКО 1.5Л']));
    expect(after.single.unitSize, 1.5);
  });

  test('createProduct and assign take unit from the name onto the product', () async {
    await catalog.ingest(['Молоко Леб 2.5% 1.7л']);
    final position = (await catalog.listPositions()).single;
    final product = await catalog.createProduct(name: 'Молоко Леб 2.5% 1.7л');
    await catalog.assignPosition(position.id, product.id);
    expect((await catalog.listProducts()).single.unit, ItemUnit.l);
    expect((await catalog.listPositions()).single.unitSize, 1.7);
  });

  test('assign does not overwrite a product unit that is already set', () async {
    await catalog.ingest(['Молоко Леб 2.5% 1.7л']);
    final position = (await catalog.listPositions()).single;
    final product = await catalog.createProduct(name: 'Молоко Леб', unit: ItemUnit.piece);
    await catalog.assignPosition(position.id, product.id);
    expect((await catalog.listProducts()).single.unit, ItemUnit.piece);
  });

  test('updatePosition can set pack size and item tags', () async {
    await catalog.ingest(['Молоко Леб 2.5% 1.7л']);
    final id = (await catalog.listPositions()).single.id;
    await catalog.updatePosition(id, unitSize: 1.75);
    expect((await catalog.listPositions()).single.unitSize, 1.75);
    await catalog.addItemTag(id, 'премиум');
    expect((await catalog.listPositions()).single.tags.single.name, 'премиум');
    await catalog.removeItemTag(id, (await catalog.listPositions()).single.tags.single.id);
    expect((await catalog.listPositions()).single.tags, isEmpty);
  });

  test('updateProduct can set and clear the unit', () async {
    final product = await catalog.createProduct(name: 'Хлеб');
    await catalog.updateProduct(product.id, unit: ItemUnit.piece);
    expect((await catalog.listProducts()).single.unit, ItemUnit.piece);
    await catalog.updateProduct(product.id, clearUnit: true);
    expect((await catalog.listProducts()).single.unit, isNull);
  });

  test('unalias splits a raw name back into its own position', () async {
    await catalog.ingest(['A', 'B']);
    final first = await catalog.listPositions();
    await catalog.mergePositions(sourceId: first[1].id, targetId: first[0].id);
    final newId = await catalog.unalias('B');
    expect(newId, isNotNull);
    final after = await catalog.listPositions();
    expect(after, hasLength(2));
    expect(after.map((e) => e.displayName), containsAll(['A', 'B']));
  });

  test('deleting a product unassigns positions', () async {
    await catalog.ingest(['Кефир']);
    final position = (await catalog.listPositions()).single;
    final product = await catalog.createProduct(name: 'Кисломолочные');
    await catalog.assignPosition(position.id, product.id);
    await catalog.deleteProduct(product.id);
    expect((await catalog.listPositions()).single.productId, isNull);
    expect(await catalog.listProducts(), isEmpty);
  });

  test('deleting a category clears product.categoryId', () async {
    final category = (await catalog.listCategories()).first;
    final product = await catalog.createProduct(name: 'Молоко', categoryId: category.id);
    await catalog.deleteCategory(category.id);
    expect((await catalog.listProducts()).single.categoryId, isNull);
    expect(product.name, 'Молоко');
  });

  test('migrates v2 receipts and seeds catalog', () async {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_migrate_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    final old = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE receipts (
            id TEXT PRIMARY KEY,
            qr_hash TEXT NOT NULL UNIQUE,
            adapter_id TEXT NOT NULL,
            status TEXT NOT NULL,
            issued_at TEXT,
            merchant_name TEXT,
            grand_total REAL NOT NULL,
            currency TEXT NOT NULL,
            item_count INTEGER NOT NULL,
            payload TEXT NOT NULL,
            scanned_at TEXT NOT NULL,
            raw_qr TEXT NOT NULL,
            last_status INTEGER NOT NULL DEFAULT 200
          )
        ''');
      },
    );
    final receipt = EqReceipt(
      id: 'old',
      issuedAt: DateTime(2026, 8, 1),
      currency: 'RUB',
      receiptType: 'sale',
      grandTotal: 10,
      items: const [EqItem(description: 'Хлеб', quantity: 1, unitPrice: 10, totalPrice: 10)],
    );
    await old.insert('receipts', {
      'id': 'r1',
      'qr_hash': 'h',
      'adapter_id': 'eq',
      'status': 'ok',
      'issued_at': receipt.issuedAt.toIso8601String(),
      'merchant_name': 'Магнит',
      'grand_total': 10,
      'currency': 'RUB',
      'item_count': 1,
      'payload': receipt.encode(),
      'scanned_at': receipt.issuedAt.toIso8601String(),
      'raw_qr': '{}',
      'last_status': 200,
    });
    await old.close();

    final migrated = CheckScanDatabase(resolvePath: () async => path);
    final catalogRepo = CatalogRepository(database: migrated);
    final receiptRepo = ReceiptRepository(database: migrated);
    expect(await catalogRepo.listCategories(), isNotEmpty);
    expect(await receiptRepo.listAll(), hasLength(1));
    await migrated.close();
  });

  test('migrates v3 position units onto products', () async {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_units_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    final old = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE categories (id TEXT PRIMARY KEY, name TEXT NOT NULL, sort_order INTEGER NOT NULL, is_seed INTEGER NOT NULL DEFAULT 0)');
        await db.execute('CREATE TABLE tags (id TEXT PRIMARY KEY, name TEXT NOT NULL, name_key TEXT NOT NULL UNIQUE)');
        await db.execute('CREATE TABLE products (id TEXT PRIMARY KEY, name TEXT NOT NULL, category_id TEXT)');
        await db.execute('CREATE TABLE product_tags (product_id TEXT NOT NULL, tag_id TEXT NOT NULL, PRIMARY KEY (product_id, tag_id))');
        await db.execute(
          'CREATE TABLE positions (id TEXT PRIMARY KEY, display_name TEXT NOT NULL, product_id TEXT, unit TEXT, unit_size REAL)',
        );
        await db.execute(
          'CREATE TABLE position_aliases (raw_name TEXT PRIMARY KEY, normalized TEXT NOT NULL, position_id TEXT NOT NULL)',
        );
      },
    );
    await old.insert('products', {'id': 'prod', 'name': 'Молоко'});
    await old.insert('positions', {
      'id': 'pos',
      'display_name': 'Молоко 1,5л',
      'product_id': 'prod',
      'unit': 'l',
      'unit_size': 1.5,
    });
    await old.close();

    final migrated = CheckScanDatabase(resolvePath: () async => path);
    final catalogRepo = CatalogRepository(database: migrated);
    expect((await catalogRepo.listProducts()).single.unit, ItemUnit.l);
    expect((await catalogRepo.listPositions()).single.unitSize, 1.5);
    await migrated.close();
  });

  test('createCategory rejects a grandchild', () async {
    final top = (await catalog.listCategories()).firstWhere((e) => e.name == '#products');
    final leaf = (await catalog.listCategories()).firstWhere((e) => e.name == '#dairyEggs');
    expect(leaf.parentId, top.id);
    expect(() => catalog.createCategory('Слишком глубоко', parentId: leaf.id), throwsStateError);
  });

  test('item tags share the dictionary with product tags', () async {
    await catalog.ingest(['Молоко']);
    final product = await catalog.createProduct(name: 'Молоко');
    await catalog.addProductTag(product.id, 'снеки');
    final item = (await catalog.listPositions()).single;
    await catalog.addItemTag(item.id, 'снеки');
    expect((await catalog.listProducts()).single.tags.single.name, 'снеки');
    expect((await catalog.listPositions()).single.tags.single.name, 'снеки');
    expect((await catalog.listProducts()).single.tags.single.id, (await catalog.listPositions()).single.tags.single.id);
  });
}
