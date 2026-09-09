import 'catalog_position.dart';

const assistPromptItemsPlaceholder = '{ items }';
const assistPromptLanguagePlaceholder = '{language}';

/// Live `ru` prompt. Do not rephrase.
const assistPromptRu =
    'Можешь объединить позиции по товарам? Название товаров должно отражать только общий класс товара, все бренды в один товар, единица измерения в товар не пишется. Названия товаров пиши на русском. Формат ответа - товары со списком позиций, без пояснений и лишней информации. Названия позиций не меняются\n'
    '\n'
    '{ items }';

/// Same instructions for later locales: product-name language is a placeholder.
const assistPromptLocalized =
    'Can you group the positions by product? Product names should reflect only the general product class, put every brand into one product, and do not write the unit of measure into the product name. Write product names in {language}. Response format: products with a list of positions, no explanations or extra information. Do not change position names.\n'
    '\n'
    '{ items }';

String formatAssistPromptItems(Iterable<CatalogPosition> positions) {
  return [for (final position in positions) '${position.id}: ${position.displayName}'].join('\n');
}

String fillAssistPrompt(String template, {required String items, String? languageName}) {
  var text = template.replaceAll(assistPromptItemsPlaceholder, items);
  if (languageName != null) {
    text = text.replaceAll(assistPromptLanguagePlaceholder, languageName);
  }
  return text;
}

String buildAssistPrompt(List<CatalogPosition> positions) {
  return fillAssistPrompt(assistPromptRu, items: formatAssistPromptItems(positions));
}

String buildAssistPromptLocalized({required String languageName, required List<CatalogPosition> positions}) {
  return fillAssistPrompt(
    assistPromptLocalized,
    items: formatAssistPromptItems(positions),
    languageName: languageName,
  );
}
