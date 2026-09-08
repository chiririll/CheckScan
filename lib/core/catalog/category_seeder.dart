import 'package:sqflite/sqflite.dart';

import '../storage/migrations/migration.dart';

const seedCategoryKeys = [
  '#dairyEggs',
  '#meat',
  '#fish',
  '#deli',
  '#produce',
  '#bakery',
  '#grocery',
  '#drinks',
  '#snacks',
  '#readyMeals',
  '#alcohol',
  '#kids',
  '#pets',
  '#beauty',
  '#pharmacy',
  '#home',
  '#other',
];

const seedTopKeys = [
  '#products',
  '#household',
  '#cafe',
  '#transport',
  '#pharmacy',
  '#other',
];

const seedChildrenOf = <String, List<String>>{
  '#products': [
    '#dairyEggs',
    '#meat',
    '#fish',
    '#deli',
    '#produce',
    '#bakery',
    '#grocery',
    '#drinks',
    '#snacks',
    '#readyMeals',
    '#alcohol',
  ],
  '#household': ['#home', '#beauty', '#kids', '#pets'],
};

Future<void> seedCategoriesIfEmpty(DatabaseExecutor db) async {
  if (!await tableExists(db, 'categories')) return;
  final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories')) ?? 0;
  if (count > 0) return;
  for (var i = 0; i < seedCategoryKeys.length; i++) {
    await db.insert('categories', {
      'id': 'seed-$i',
      'name': seedCategoryKeys[i],
      'sort_order': i,
      'is_seed': 1,
    });
  }
}

Future<void> seedTwoLevelCategories(DatabaseExecutor db) async {
  if (!await tableExists(db, 'category')) return;
  final existing = await db.query('category');
  final byName = <String, int>{
    for (final row in existing) '${row['name']}': (row['id'] as num).toInt(),
  };

  var sort = 0;
  for (final key in seedTopKeys) {
    if (byName.containsKey(key)) continue;
    final id = await db.insert('category', {
      'name': key,
      'parent_id': null,
      'sort_order': sort,
      'icon': null,
    });
    byName[key] = id;
    sort += 1;
  }

  for (final entry in seedChildrenOf.entries) {
    final parentId = byName[entry.key];
    if (parentId == null) continue;
    var childSort = 0;
    for (final child in entry.value) {
      final existingId = byName[child];
      if (existingId != null) {
        await db.update('category', {'parent_id': parentId, 'sort_order': childSort}, where: 'id = ?', whereArgs: [existingId]);
      } else {
        final id = await db.insert('category', {
          'name': child,
          'parent_id': parentId,
          'sort_order': childSort,
          'icon': null,
        });
        byName[child] = id;
      }
      childSort += 1;
    }
  }

  for (final key in ['#pharmacy', '#other', '#cafe', '#transport', '#products', '#household']) {
    final id = byName[key];
    if (id == null) continue;
    await db.update('category', {'parent_id': null}, where: 'id = ?', whereArgs: [id]);
  }
}
