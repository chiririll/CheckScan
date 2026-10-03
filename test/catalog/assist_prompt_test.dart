import 'package:checkscan/core/catalog/assist/assist_cluster.dart';
import 'package:checkscan/core/catalog/assist/assist_prompt.dart';
import 'package:checkscan/core/catalog/model/catalog_position.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prompt lists every unassigned item and drops the items placeholder', () {
    final positions = [
      for (var i = 0; i < 30; i++) CatalogPosition(id: '$i', displayName: 'Позиция $i'),
    ];
    final text = buildAssistPrompt(positions);
    expect(text, startsWith('Можешь объединить позиции по товарам?'));
    expect(text, contains('Названия товаров пиши на русском'));
    expect(text, isNot(contains(assistPromptItemsPlaceholder)));
    expect(nextAssistBatch(positions), hasLength(assistBatchLimit));
    expect(positions.length, greaterThan(assistBatchLimit));
    for (final position in positions) {
      expect(text, contains('${position.id}: ${position.displayName}'));
    }
  });

  test('localized sibling substitutes language and items', () {
    final text = buildAssistPromptLocalized(
      languageName: 'English',
      positions: const [CatalogPosition(id: '1', displayName: 'Milk')],
    );
    expect(text, contains('English'));
    expect(text, isNot(contains(assistPromptLanguagePlaceholder)));
    expect(text, isNot(contains(assistPromptItemsPlaceholder)));
    expect(text, contains('1: Milk'));
  });
}
