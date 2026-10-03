import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations/migration.dart';
import 'migrations/v1_receipts.dart';
import 'migrations/v2_last_status.dart';
import 'migrations/v3_catalog.dart';
import 'migrations/v4_product_units.dart';
import 'migrations/v5_position_brand.dart';
import 'migrations/v6_catalog_model.dart';
import 'migrations/v7_suggestion_ignore.dart';
import 'migrations/v8_receipt_format.dart';

export 'migrations/v1_receipts.dart' show createReceiptsTable;
export 'migrations/v3_catalog.dart' show createCatalogTables;
export 'migrations/v4_product_units.dart' show migrateCatalogUnitsToProducts;
export 'migrations/v5_position_brand.dart' show migratePositionBrand;

const checkScanDbVersion = 8;

final checkScanMigrations = [
  v1Receipts,
  v2LastStatus,
  v3Catalog,
  v4ProductUnits,
  v5PositionBrand,
  v6CatalogModel,
  v7SuggestionIgnore,
  v8ReceiptFormat,
];

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
      onCreate: (db, version) => runMigrations(db, fromExclusive: 0, toInclusive: version, steps: checkScanMigrations),
      onUpgrade: (db, oldVersion, newVersion) =>
          runMigrations(db, fromExclusive: oldVersion, toInclusive: newVersion, steps: checkScanMigrations),
    );
    return _db!;
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) await db.close();
  }
}
