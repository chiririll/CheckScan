import 'package:checkscan/core/catalog/text/name_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes case, punctuation and spaces before units', () {
    expect(normalizeItemName('Молоко Леб 2.5% 1.7л'), 'молоко леб 2.5% 1.7л');
    expect(normalizeItemName('МОЛОКО ЛЕБ 2,5% 1,7 Л'), 'молоко леб 2.5% 1.7л');
    expect(normalizeItemName('MLEKO IMLEK 2,8% 1,5 L'), 'mleko imlek 2.8% 1.5l');
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
