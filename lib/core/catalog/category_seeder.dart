import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

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

Future<void> seedCategoriesIfEmpty(DatabaseExecutor db) async {
  final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories')) ?? 0;
  if (count > 0) return;
  for (var i = 0; i < seedCategoryKeys.length; i++) {
    await db.insert('categories', {
      'id': const Uuid().v4(),
      'name': seedCategoryKeys[i],
      'sort_order': i,
      'is_seed': 1,
    });
  }
}
