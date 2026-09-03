import 'package:checkscan/core/catalog/catalog_category.dart';
import 'package:checkscan/core/catalog/catalog_position.dart';
import 'package:checkscan/core/catalog/catalog_product.dart';
import 'package:checkscan/core/catalog/catalog_resolver.dart';
import 'package:checkscan/features/receipt_detail/receipt_items.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups mapped items by category and leaves the rest uncategorized', () {
    const resolver = CatalogResolver(
      byRawName: {'Молоко 1 л': 'p1', 'Хлеб': 'p2'},
      positions: {
        'p1': CatalogPosition(id: 'p1', displayName: 'Молоко 1 л', productId: 'milk'),
        'p2': CatalogPosition(id: 'p2', displayName: 'Хлеб'),
      },
      products: {
        'milk': CatalogProduct(id: 'milk', name: 'Молоко', categoryId: 'dairy'),
      },
      categories: {
        'dairy': CatalogCategory(id: 'dairy', name: 'Молочные', sortOrder: 0, isSeed: true),
      },
    );
    const items = [
      EqItem(description: 'Молоко 1 л', quantity: 1, unitPrice: 80, totalPrice: 80),
      EqItem(description: 'Хлеб', quantity: 1, unitPrice: 80, totalPrice: 80),
    ];

    final groups = groupReceiptItems(items, resolver, 'Без категории');
    expect(groups, hasLength(2));
    expect(groups[0].title, 'Молочные');
    expect(groups[0].items.single.description, 'Молоко 1 л');
    expect(groups[1].title, 'Без категории');
    expect(groups[1].items.single.description, 'Хлеб');
  });

  test('does not add headers when nothing is categorized', () {
    const items = [EqItem(description: 'Молоко 1 л', quantity: 1, unitPrice: 80, totalPrice: 80)];
    final groups = groupReceiptItems(items, CatalogResolver.empty, 'Без категории');
    expect(groups, hasLength(1));
    expect(groups.single.title, isNull);
    expect(groups.single.items, items);
  });
}
