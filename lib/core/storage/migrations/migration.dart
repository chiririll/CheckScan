import 'package:sqflite/sqflite.dart';

class Migration {
  const Migration({required this.version, required this.up});

  final int version;
  final Future<void> Function(DatabaseExecutor db) up;
}

Future<void> runMigrations(
  DatabaseExecutor db, {
  required int fromExclusive,
  required int toInclusive,
  required List<Migration> steps,
}) async {
  for (final step in steps) {
    if (step.version > fromExclusive && step.version <= toInclusive) {
      await step.up(db);
    }
  }
}

Future<bool> tableExists(DatabaseExecutor db, String name) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
    [name],
  );
  return rows.isNotEmpty;
}

Future<bool> columnExists(DatabaseExecutor db, String table, String column) async {
  if (!await tableExists(db, table)) return false;
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.any((row) => '${row['name']}' == column);
}
