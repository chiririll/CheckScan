import 'package:checkscan/core/catalog/name_stem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('strips fat percent and pack size', () {
    expect(itemNameStem('Молоко Леб 2.5% 1.7л'), 'молоко леб');
    expect(itemNameStem('МОЛОКО ЛЕБ 2,5% 0,93Л'), 'молоко леб');
    expect(itemNameStem('Хлеб дарницкий нар. 0,6кг'), 'хлеб дарницкий нар');
  });

  test('keeps product words when there is no size', () {
    expect(itemNameStem('Кефир'), 'кефир');
    expect(itemNameStem('Суп домашний'), 'суп домашний');
  });
}
