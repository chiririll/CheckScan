import 'package:checkscan/core/format/format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  test('currency labels map known codes and pass others through', () {
    expect(formatCurrencyLabel('RUB'), '₽');
    expect(formatCurrencyLabel('RSD'), 'дин.');
    expect(formatCurrencyLabel('EUR'), 'EUR');
    expect(formatMoney(5, 'EUR'), endsWith(' EUR'));
    expect(formatMoney(5), endsWith(' ₽'));
  });

  test('parseDecimal accepts a decimal comma and rejects junk', () {
    expect(parseDecimal('1,5'), 1.5);
    expect(parseDecimal(' 2 '), 2);
    expect(parseDecimal('abc'), isNull);
  });
}
