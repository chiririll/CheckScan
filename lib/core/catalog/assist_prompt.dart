import 'catalog_category.dart';
import 'catalog_position.dart';
import 'catalog_product.dart';
import 'item_unit.dart';

class AssistCategoryHint {
  const AssistCategoryHint({required this.id, required this.label});

  final String id;
  final String label;
}

List<AssistCategoryHint> assistCategoryHints(
  List<CatalogCategory> categories,
  String Function(CatalogCategory category) labelOf,
) {
  return [for (final category in categories) AssistCategoryHint(id: category.isSeed ? category.name : category.id, label: labelOf(category))];
}

String buildAssistPrompt({
  required String languageName,
  required List<AssistCategoryHint> categories,
  required List<CatalogProduct> products,
  required List<CatalogPosition> positions,
}) {
  final buffer = StringBuffer()
    ..writeln('Разбери позиции чека в каталог.')
    ..writeln('Язык приложения: $languageName. Названия товаров (products[].name) пиши на этом языке, без фасовки.')
    ..writeln('Названия позиций из чека не меняй и не переводи.')
    ..writeln('У позиции укажи brand — производитель или марка, на языке приложения. Разные марки не сливай в одну позицию.')
    ..writeln('В category пиши id из списка ниже, не подпись. Новую категорию создавай только если ни одна не подходит — имя на языке приложения.')
    ..writeln('Единицы: ${[for (final unit in ItemUnit.values) unit.name].join(', ')}.')
    ..writeln()
    ..writeln('Категории:');
  for (final category in categories) {
    buffer.writeln('- id: ${category.id} | ${category.label}');
  }
  buffer.writeln();
  if (products.isNotEmpty) {
    buffer.writeln('Уже есть похожие товары:');
    for (final product in products) {
      buffer.writeln(
        '- id: ${product.id} | ${product.name}'
        '${product.unit == null ? '' : ' | unit: ${product.unit!.name}'}'
        '${product.categoryId == null ? '' : ' | categoryId: ${product.categoryId}'}',
      );
    }
    buffer.writeln();
  }
  buffer
    ..writeln('Позиции:')
    ..writeln('[');
  for (var i = 0; i < positions.length; i++) {
    final position = positions[i];
    final size = position.unitSize;
    buffer.write('  {"id": "${position.id}", "name": ${_jsonString(position.displayName)}');
    if (size != null) buffer.write(', "unitSize": $size');
    if (position.brand != null && position.brand!.isNotEmpty) {
      buffer.write(', "brand": ${_jsonString(position.brand!)}');
    }
    buffer.write('}');
    if (i != positions.length - 1) buffer.write(',');
    buffer.writeln();
  }
  buffer
    ..writeln(']')
    ..writeln()
    ..writeln('Верни только JSON:')
    ..writeln('{')
    ..writeln('  "categories": [{"name": "Новая категория"}],')
    ..writeln('  "products": [')
    ..writeln('    {')
    ..writeln('      "name": "Товар",')
    ..writeln('      "category": "#dairyEggs",')
    ..writeln('      "unit": "l",')
    ..writeln('      "existingProductId": null,')
    ..writeln('      "positions": [{"id": "<id из списка>", "unitSize": 1.7, "brand": "Леб"}]')
    ..writeln('    }')
    ..writeln('  ]')
    ..writeln('}');
  return buffer.toString();
}

String _jsonString(String value) {
  return '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
}
