import 'package:sqflite/sqflite.dart';

import '../../storage/database.dart';

/// Shared handle for the per-table mixins of [CatalogRepository].
abstract class CatalogTables {
  CatalogTables({required this.database});

  final CheckScanDatabase database;

  Future<Database> get db => database.database;
}
