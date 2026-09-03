import 'package:checkscan/core/catalog/name_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes case, punctuation and spaces before units', () {
    expect(normalizeItemName('МОЛОКО 1,5 Л'), 'молоко 1.5л');
    expect(normalizeItemName('Молоко 1.5Л'), 'молоко 1.5л');
    expect(normalizeItemName('молоко  простоквашино  1.5%'), 'молоко простоквашино 1.5%');
  });

  test('keeps letters from any script after case fold', () {
    expect(normalizeItemName('Ёлка'), 'ёлка');
    expect(normalizeItemName('Đak hleb'), 'đak hleb');
  });

  test('tagNameKey is a trimmed Unicode case fold', () {
    expect(tagNameKey(' Ёлка '), 'ёлка');
    expect(tagNameKey(' Đak '), 'đak');
    expect(tagNameKey('Milk'), 'milk');
  });
}
