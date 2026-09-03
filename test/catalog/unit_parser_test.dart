import 'package:checkscan/core/catalog/item_unit.dart';
import 'package:checkscan/core/catalog/unit_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses volume and mass with size', () {
    expect(parseItemUnit('Молоко 1,5л')?.unit, ItemUnit.l);
    expect(parseItemUnit('Молоко 1,5л')?.size, 1.5);
    expect(parseItemUnit('1.5 л')?.unit, ItemUnit.l);
    expect(parseItemUnit('900мл')?.unit, ItemUnit.ml);
    expect(parseItemUnit('900мл')?.size, 900);
    expect(parseItemUnit('0,5 кг')?.unit, ItemUnit.kg);
    expect(parseItemUnit('400г')?.unit, ItemUnit.g);
    expect(parseItemUnit('400г')?.size, 400);
  });

  test('does not treat fat percent as volume', () {
    final parsed = parseItemUnit('Молоко 1,5% 1 л');
    expect(parsed?.unit, ItemUnit.l);
    expect(parsed?.size, 1);
    expect(parseItemUnit('Молоко 1,5%'), isNull);
  });

  test('parses piece and pack without size', () {
    expect(parseItemUnit('Яйцо 10 шт')?.unit, ItemUnit.piece);
    expect(parseItemUnit('Яйцо 10 шт')?.size, isNull);
    expect(parseItemUnit('x10шт')?.unit, ItemUnit.piece);
    expect(parseItemUnit('Печенье упак')?.unit, ItemUnit.pack);
    expect(parseItemUnit('Суп домашний'), isNull);
  });
}
