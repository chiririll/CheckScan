import 'package:checkscan/core/catalog/category_label.dart';
import 'package:checkscan/l10n/app_localizations_ru.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsRu();

  test('resolves seed keys and leaves custom names as-is', () {
    expect(categoryLabel('#dairyEggs', l10n), 'Молочные и яйца');
    expect(categoryLabel('#pets', l10n), 'Товары для животных');
    expect(categoryLabel('#other', l10n), 'Прочее');
    expect(categoryLabel('Своя полка', l10n), 'Своя полка');
  });
}
