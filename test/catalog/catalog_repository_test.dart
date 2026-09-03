import 'dart:io';

import 'package:checkscan/core/catalog/catalog_repository.dart';
import 'package:checkscan/core/catalog/item_unit.dart';
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
    expect(categories.map((e) => e.name), containsAll(['#dairyEggs', '#other']));
    expect(categories.every((e) => e.isSeed), isTrue);
  });

  test('ingest creates a position with parsed unit only once', () async {
    await catalog.ingest(['Молоко 1,5л', 'Молоко 1,5л']);
    final positions = await catalog.listPositions();
    expect(positions, hasLength(1));
    expect(positions.single.unit, ItemUnit.l);
    expect(positions.single.unitSize, 1.5);
    expect(positions.single.aliases, ['Молоко 1,5л']);
  });

  test('does not overwrite unit on a later alias of a new raw name', () async {
    await catalog.ingest(['Хлеб']);
    await catalog.updatePosition( (await catalog.listPositions()).single.id, unit: ItemUnit.piece);
    await catalog.ingest(['Хлеб', 'Батон']);
    final positions = await catalog.listPositions();
    final bread = positions.firstWhere((e) => e.displayName == 'Хлеб');
    expect(bread.unit, ItemUnit.piece);
    expect(positions.where((e) => e.displayName == 'Батон').single.unit, isNull);
  });

  test('merge moves aliases and copies unit when target is empty', () async {
    await catalog.ingest(['Молоко 1,5 л', 'МОЛОКО 1.5Л']);
    final positions = await catalog.listPositions();
    final source = positions.firstWhere((e) => e.displayName == 'МОЛОКО 1.5Л');
    final target = positions.firstWhere((e) => e.displayName == 'Молоко 1,5 л');
    await catalog.mergePositions(sourceId: source.id, targetId: target.id);
    final after = await catalog.listPositions();
    expect(after, hasLength(1));
    expect(after.single.aliases, containsAll(['Молоко 1,5 л', 'МОЛОКО 1.5Л']));
    expect(after.single.unit, ItemUnit.l);
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
}
