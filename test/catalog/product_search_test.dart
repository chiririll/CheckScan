import 'dart:io';

import 'package:checkscan/core/catalog/catalog_store.dart';
import 'package:checkscan/core/catalog/data/catalog_repository.dart';
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
  late CatalogStore store;

  setUp(() async {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_search_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    store = CatalogStore(repository: CatalogRepository(database: database));
    await CatalogRepository(database: database).ingest([
      'Молоко Леб 1.7л',
      'Молоко Домик 1л',
      'Хлеб дарницкий',
      'Кефир 900мл',
    ]);
    final milk = await store.createProduct(name: 'Молоко');
    final bread = await store.createProduct(name: 'Хлеб');
    final positions = store.positions;
    await store.assignPosition(positions.firstWhere((e) => e.displayName.contains('Леб')).id, milk.id);
    await store.assignPosition(positions.firstWhere((e) => e.displayName.startsWith('Хлеб')).id, bread.id);
  });

  tearDown(() async {
    await database.close();
  });

  test('search finds unassigned and already assigned names', () async {
    final milk = store.products.firstWhere((e) => e.name == 'Молоко');
    final own = store.searchAttachableItems(milk.id, 'леб 1.7');
    expect(own, isEmpty);
    final kefir = store.searchAttachableItems(milk.id, 'кефир');
    expect(kefir.single.displayName, 'Кефир 900мл');
    final bread = store.searchAttachableItems(milk.id, 'дарницк');
    expect(bread.single.displayName, 'Хлеб дарницкий');
    expect(bread.single.productId, isNotNull);
  });

  test('similar candidates come from the unassigned cluster', () async {
    final milk = store.products.firstWhere((e) => e.name == 'Молоко');
    final similar = store.similarCandidatesFor(milk.id);
    expect(similar.map((e) => e.displayName), contains('Молоко Домик 1л'));
    expect(similar.map((e) => e.displayName), isNot(contains('Кефир 900мл')));
  });
}
