import 'package:checkscan/features/labels/category_label.dart';
import 'package:checkscan/l10n/app_localizations_ru.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsRu();

  test('resolves seed keys and leaves custom names as-is', () {
    expect(categoryLabel('#dairyEggs', l10n), 'Молочные и яйца');
    expect(categoryLabel('#pets', l10n), 'Товары для животных');
    expect(categoryLabel('#other', l10n), 'Прочее');
    expect(categoryLabel('#products', l10n), 'Продукты');
    expect(categoryLabel('#household', l10n), 'Для дома');
    expect(categoryLabel('#cafe', l10n), 'Кафе');
    expect(categoryLabel('Своя полка', l10n), 'Своя полка');
  });
}
