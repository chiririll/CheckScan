import 'package:checkscan/core/catalog/assist_prompt.dart';
import 'package:checkscan/core/catalog/catalog_position.dart';
import 'package:checkscan/core/catalog/catalog_product.dart';
import 'package:checkscan/core/catalog/item_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prompt lists language, the batch, and similar products only', () {
    final text = buildAssistPrompt(
      languageName: 'русский',
      categories: const [AssistCategoryHint(id: '#dairyEggs', label: 'Молочные и яйца')],
      products: const [CatalogProduct(id: 'milk', name: 'Молоко', unit: ItemUnit.l)],
      positions: const [
        CatalogPosition(id: 'pos-1', displayName: 'Молоко Леб 2.5% 1.7л', unitSize: 1.7),
      ],
    );
    expect(text, contains('русский'));
    expect(text, contains('pos-1'));
    expect(text, contains('Молоко Леб 2.5% 1.7л'));
    expect(text, contains('#dairyEggs'));
    expect(text, contains('milk'));
    expect(text, isNot(contains('Хлеб дарницкий')));
    expect(text, isNot(contains('bread-id')));
  });
}
