import 'dart:io';

import 'package:checkscan/core/catalog/category_seeder.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _seq = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('seeds only when categories are empty and does not restore deletes', () async {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_seed_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    final db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await createCatalogTables(db);
      },
    );
    await seedCategoriesIfEmpty(db);
    await db.delete('categories', where: 'name = ?', whereArgs: ['#other']);
    await seedCategoriesIfEmpty(db);
    final rows = await db.query('categories');
    expect(rows.map((row) => '${row['name']}'), isNot(contains('#other')));
    expect(rows, hasLength(seedCategoryKeys.length - 1));
    await db.close();
  });
}
