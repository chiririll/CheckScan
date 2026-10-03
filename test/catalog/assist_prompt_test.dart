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
    for (final position in positions) {
      expect(text, contains('${position.id}: ${position.displayName}'));
    }
  });
}
