import 'package:checkscan/core/catalog/item_unit.dart';
import 'package:checkscan/core/catalog/unit_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('picks the pack size off a noisy receipt line', () {
    const cases = <(String, ItemUnit, double?)>[
      ('Молоко Леб 2.5% 1.7л', ItemUnit.l, 1.7),
      ('МОЛ ПАСТЕР 3,2% 930МЛ', ItemUnit.ml, 930),
      ('Сыр росс 45% 200г', ItemUnit.g, 200),
      ('Хлеб дарницкий нар. 0,6кг', ItemUnit.kg, 0.6),
      ('Яйцо С1 фас. 10шт', ItemUnit.piece, null),
      ('Печенье юбил. упак', ItemUnit.pack, null),
      ('MLEKO IMLEK 2,8% 1,5L', ItemUnit.l, 1.5),
      ('JOGURT GREKI 2.5% 400G', ItemUnit.g, 400),
      ('ULJE SUNCOKRET 1L', ItemUnit.l, 1),
      ('ŠEĆER KRISTAL 1KG', ItemUnit.kg, 1),
      ('JAJA A KLAS 10 KOM', ItemUnit.piece, null),
      ('KEKS JADRAN PAK', ItemUnit.pack, null),
    ];
    for (final (raw, unit, size) in cases) {
      final parsed = parseItemUnit(raw);
      expect(parsed?.unit, unit, reason: raw);
      expect(parsed?.size, size, reason: raw);
    }
  });

  test('keeps measure sizes with separators but does not invent size for piece or pack', () {
    expect(parseItemUnit('Молоко 1,5\u00a0л')?.size, 1.5);
    expect(parseItemUnit('Хлеб 400\u202fг')?.size, 400);
    expect(parseItemUnit('Сахар 1 x кг')?.size, 1);
    expect(parseItemUnit('Яйцо 10 шт')?.unit, ItemUnit.piece);
    expect(parseItemUnit('Яйцо 10 шт')?.size, isNull);
    expect(parseItemUnit('Яйцо x10шт')?.size, isNull);
    expect(parseItemUnit('Печенье 2 упак')?.unit, ItemUnit.pack);
    expect(parseItemUnit('Печенье 2 упак')?.size, isNull);
  });

  test('prefers the pack size at the end over an earlier number', () {
    final parsed = parseItemUnit('Напиток 0,5л пэт 1.5л');
    expect(parsed?.unit, ItemUnit.l);
    expect(parsed?.size, 1.5);
  });

  test('does not treat fat percent or a bare number as the pack size', () {
    expect(parseItemUnit('Молоко Леб 2.5%'), isNull);
    expect(parseItemUnit('Сыр росс 45%'), isNull);
    expect(parseItemUnit('Молоко 1,5'), isNull);
    expect(parseItemUnit('Хлеб 400'), isNull);
    final glued = parseItemUnit('Молоко Леб 2.5%1.7л');
    expect(glued?.unit, ItemUnit.l);
    expect(glued?.size, 1.7);
  });

  test('ignores full unit words that do not appear on receipts', () {
    expect(parseItemUnit('Молоко Леб 2.5% 1 литр'), isNull);
    expect(parseItemUnit('MLEKO IMLEK 1,5 litar'), isNull);
    expect(parseItemUnit('JAJA 10 komada'), isNull);
  });
}
