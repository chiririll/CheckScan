import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../catalog/category_seeder.dart';

const checkScanDbVersion = 3;

class CheckScanDatabase {
  CheckScanDatabase({this._resolvePath});

  final Future<String> Function()? _resolvePath;
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final resolver = _resolvePath;
    final path = resolver != null
        ? await resolver()
        : p.join((await getApplicationDocumentsDirectory()).path, 'checkscan.db');
    _db = await openDatabase(
      path,
      version: checkScanDbVersion,
      onCreate: (db, version) async {
        await createReceiptsTable(db);
        await createCatalogTables(db);
        await seedCategoriesIfEmpty(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE receipts ADD COLUMN last_status INTEGER NOT NULL DEFAULT 200');
        }
        if (oldVersion < 3) {
          await createCatalogTables(db);
          await seedCategoriesIfEmpty(db);
        }
      },
    );
    return _db!;
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) await db.close();
  }
}

Future<void> createReceiptsTable(DatabaseExecutor db) async {
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
  await db.execute('CREATE UNIQUE INDEX idx_receipts_qr_hash ON receipts(qr_hash)');
}

Future<void> createCatalogTables(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      sort_order INTEGER NOT NULL,
      is_seed INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE tags (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      name_key TEXT NOT NULL UNIQUE
    )
  ''');
  await db.execute('''
    CREATE TABLE products (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      category_id TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE product_tags (
      product_id TEXT NOT NULL,
      tag_id TEXT NOT NULL,
      PRIMARY KEY (product_id, tag_id)
    )
  ''');
  await db.execute('''
    CREATE TABLE positions (
      id TEXT PRIMARY KEY,
      display_name TEXT NOT NULL,
      product_id TEXT,
      unit TEXT,
      unit_size REAL
    )
  ''');
  await db.execute('''
    CREATE TABLE position_aliases (
      raw_name TEXT PRIMARY KEY,
      normalized TEXT NOT NULL,
      position_id TEXT NOT NULL
    )
  ''');
  await db.execute('CREATE INDEX idx_position_aliases_normalized ON position_aliases(normalized)');
  await db.execute('CREATE INDEX idx_positions_product ON positions(product_id)');
}
