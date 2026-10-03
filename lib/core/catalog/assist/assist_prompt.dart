import '../model/catalog_position.dart';

const assistPromptItemsPlaceholder = '{ items }';

/// Live `ru` prompt. Do not rephrase.
const assistPromptRu =
    'Можешь объединить позиции по товарам? Название товаров должно отражать только общий класс товара, все бренды в один товар, единица измерения в товар не пишется. Названия товаров пиши на русском. Формат ответа - товары со списком позиций, без пояснений и лишней информации. Названия позиций не меняются\n'
    '\n'
    '{ items }';

/// Prompt with one `id: name` line per position.
String buildAssistPrompt(List<CatalogPosition> positions) {
  final items = [for (final position in positions) '${position.id}: ${position.displayName}'].join('\n');
  return assistPromptRu.replaceAll(assistPromptItemsPlaceholder, items);
}
