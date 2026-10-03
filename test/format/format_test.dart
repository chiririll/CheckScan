import 'package:checkscan/core/format/format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  test('currency labels map known codes and pass others through', () {
    expect(formatCurrencyLabel('RUB'), '₽');
    expect(formatCurrencyLabel('RSD'), 'дин.');
    expect(formatCurrencyLabel('EUR'), 'EUR');
    expect(formatMoney(500, 'EUR'), endsWith(' EUR'));
    expect(formatMoney(500), endsWith(' ₽'));
  });

  test('formatMoney takes minor units and never goes through double', () {
    String plain(String s) => s.replaceAll(RegExp(r'\s'), ' ');
    expect(plain(formatMoney(124700)), '1 247 ₽');
    expect(plain(formatMoney(17850)), '178,50 ₽');
    expect(plain(formatMoney(5)), '0,05 ₽');
    expect(plain(formatMoney(-8999, 'RSD')), '-89,99 дин.');
    expect(plain(formatMoney(999999999999999, 'RUB')), '9 999 999 999 999,99 ₽');
  });
}
