import 'package:checkscan/core/catalog/assist_draft.dart';
import 'package:checkscan/core/catalog/assist_parse.dart';
import 'package:checkscan/core/catalog/catalog_category.dart';
import 'package:checkscan/core/catalog/catalog_position.dart';
import 'package:checkscan/core/catalog/catalog_product.dart';
import 'package:checkscan/core/catalog/item_unit.dart';
import 'package:flutter_test/flutter_test.dart';

const _dairy = CatalogCategory(id: 'cat-dairy', name: '#dairyEggs', sortOrder: 0, isSeed: true);
const _custom = CatalogCategory(id: 'cat-custom', name: 'Своя', sortOrder: 1, isSeed: false);
const _pos = CatalogPosition(id: 'pos-1', displayName: 'Молоко Леб 2.5% 1.7л', unitSize: 1.7);
const _ctx = AssistParseContext(
  categories: [_dairy, _custom],
  products: [CatalogProduct(id: 'milk', name: 'Молоко')],
  positions: [_pos],
  seedLabels: {'#dairyEggs': 'Молочные и яйца'},
);

void main() {
  test('rejects empty, non-json and missing products', () {
    expect(parseAssistJson('', _ctx).error, AssistParseError.empty);
    expect(parseAssistJson('не json', _ctx).error, AssistParseError.notJson);
    expect(parseAssistJson('{"categories":[]}', _ctx).error, AssistParseError.noProducts);
    expect(parseAssistJson('{"products":[]}', _ctx).error, AssistParseError.nothingToApply);
  });

  test('unwraps a fenced chat reply', () {
    const raw = '''вот json
```json
{"products":[{"name":"Молоко","category":"#dairyEggs","unit":"l","positions":[{"id":"pos-1","unitSize":1.7}]}]}
```
''';
    final result = parseAssistJson(raw, _ctx);
    expect(result.isOk, isTrue);
    expect(result.draft!.products.single.name, 'Молоко');
    expect(result.draft!.products.single.existingCategoryId, 'cat-dairy');
    expect(result.draft!.products.single.unit, ItemUnit.l);
    expect(result.draft!.products.single.positions.single.unitSize, 1.7);
  });

  test('reads brand from a position row', () {
    final result = parseAssistJson(
      '{"products":[{"name":"Молоко","positions":[{"id":"pos-1","unitSize":1.7,"brand":"Леб"}]}]}',
      _ctx,
    );
    expect(result.draft!.products.single.positions.single.brand, 'Леб');
  });

  test('maps a seed label to the seed and does not invent a category', () {
    final result = parseAssistJson(
      '{"products":[{"name":"Молоко","category":"Молочные и яйца","positions":[{"id":"pos-1"}]}]}',
      _ctx,
    );
    expect(result.draft!.newCategories, isEmpty);
    expect(result.draft!.products.single.existingCategoryId, 'cat-dairy');
  });

  test('collects a new category from the list and from a product field', () {
    final result = parseAssistJson(
      '{"categories":[{"name":"Заморозка"}],"products":[{"name":"Пельмени","category":"Заморозка","positions":[{"id":"pos-1"}]}]}',
      _ctx,
    );
    expect(result.draft!.newCategories.single.name, 'Заморозка');
    expect(result.draft!.products.single.newCategoryKey, 'заморозка');
  });

  test('drops a broken product row and an unknown position id', () {
    final result = parseAssistJson(
      '{"products":[{"name":""},{"name":"Молоко","positions":[{"id":"unknown"},{"id":"pos-1"}]}]}',
      _ctx,
    );
    expect(result.draft!.skippedCount, greaterThan(0));
    expect(result.draft!.products.single.positions.single.id, 'pos-1');
  });

  test('keeps existingProductId only when the product exists', () {
    final result = parseAssistJson(
      '{"products":[{"name":"Молоко","existingProductId":"milk","positions":[{"id":"pos-1"}]}]}',
      _ctx,
    );
    expect(result.draft!.products.single.existingProductId, 'milk');
    final missing = parseAssistJson(
      '{"products":[{"name":"Молоко","existingProductId":"nope","positions":[{"id":"pos-1"}]}]}',
      _ctx,
    );
    expect(missing.draft!.products.single.existingProductId, isNull);
  });

  test('moderation helpers drop a category and a product', () {
    const draft = AssistDraft(
      newCategories: [AssistNewCategory(key: 'заморозка', name: 'Заморозка')],
      products: [
        AssistDraftProduct(name: 'Пельмени', newCategoryKey: 'заморозка', positions: [AssistDraftPosition(id: 'pos-1')]),
        AssistDraftProduct(name: 'Молоко', positions: [AssistDraftPosition(id: 'pos-2')]),
      ],
    );
    final withoutCat = draft.withoutCategory('заморозка');
    expect(withoutCat.newCategories, isEmpty);
    expect(withoutCat.products.first.newCategoryKey, isNull);
    expect(draft.withoutProduct(0).products.single.name, 'Молоко');
  });
}
