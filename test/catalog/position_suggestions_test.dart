import 'package:checkscan/core/catalog/catalog_position.dart';
import 'package:checkscan/core/catalog/position_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('suggests the same normalized name', () {
    const other = CatalogPosition(id: 'p1', displayName: 'МОЛОКО 1.5Л');
    final found = suggestPositionMerges('Молоко 1,5 л', positions: const [other]);
    expect(found.single.id, 'p1');
  });

  test('does not suggest different pack sizes', () {
    const other = CatalogPosition(id: 'p2', displayName: 'Молоко 2 л');
    expect(suggestPositionMerges('Молоко 1 л', positions: const [other]), isEmpty);
  });

  test('skips the same position id', () {
    const current = CatalogPosition(id: 'p1', displayName: 'Молоко 1,5 л');
    expect(suggestPositionMerges('Молоко 1,5 л', positions: const [current], excludeId: 'p1'), isEmpty);
  });
}
