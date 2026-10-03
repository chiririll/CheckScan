import 'package:checkscan/core/catalog/catalog_resolver.dart';
import 'package:checkscan/core/catalog/model/catalog_category.dart';
import 'package:checkscan/core/catalog/model/catalog_position.dart';
import 'package:checkscan/core/catalog/model/catalog_product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('from() resolves every alias to its position, product and category', () {
    final resolver = CatalogResolver.from(
      categories: const [CatalogCategory(id: 'dairy', name: '#dairyEggs', sortOrder: 0)],
      products: const [CatalogProduct(id: 'milk', name: 'Молоко', categoryId: 'dairy')],
      positions: const [
        CatalogPosition(id: 'p1', displayName: 'Молоко 1л', productId: 'milk', aliases: ['МОЛОКО 1Л', 'Молоко 1л']),
        CatalogPosition(id: 'p2', displayName: 'Хлеб', aliases: ['Хлеб']),
      ],
    );

    final hit = resolver.resolve('МОЛОКО 1Л')!;
    expect(hit.position.id, 'p1');
    expect(hit.product?.id, 'milk');
    expect(resolver.categoryName('Молоко 1л'), '#dairyEggs');

    final bare = resolver.resolve('Хлеб')!;
    expect(bare.product, isNull);
    expect(resolver.resolve('нет такого'), isNull);
  });
}
