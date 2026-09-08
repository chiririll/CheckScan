import 'package:checkscan/core/catalog/catalog_category.dart';
import 'package:checkscan/core/catalog/category_top.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const top = CatalogCategory(id: '1', name: '#products', sortOrder: 0);
  const leaf = CatalogCategory(id: '2', name: '#dairyEggs', parentId: '1', sortOrder: 1);
  const byId = {'1': top, '2': leaf};

  test('leaf walks to the envelope', () {
    expect(topCategoryOf(categoryId: '2', byId: byId)?.name, '#products');
  });

  test('top stays itself', () {
    expect(topCategoryOf(categoryId: '1', byId: byId)?.id, '1');
  });

  test('missing id is null', () {
    expect(topCategoryOf(categoryId: 'nope', byId: byId), isNull);
    expect(topCategoryOf(categoryId: null, byId: byId), isNull);
  });
}
