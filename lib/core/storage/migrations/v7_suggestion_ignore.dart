import 'package:sqflite/sqflite.dart';

import 'migration.dart';

const v7SuggestionIgnore = Migration(version: 7, up: createSuggestionIgnoreTables);

Future<void> createSuggestionIgnoreTables(DatabaseExecutor db) async {
  if (!await tableExists(db, 'cluster_ignore')) {
    await db.execute('''
      CREATE TABLE cluster_ignore (
        item_id INTEGER PRIMARY KEY
      )
    ''');
  }
  if (!await tableExists(db, 'product_suggestion_ignore')) {
    await db.execute('''
      CREATE TABLE product_suggestion_ignore (
        product_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        PRIMARY KEY (product_id, item_id)
      )
    ''');
  }
}
