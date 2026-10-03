import 'package:checkscan/core/currency/currencies.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/receipt_fixtures.dart';

ReceiptRecord _in(String currency, String id) => testRecord(testReceipt(id: id, currency: currency));

void main() {
  test('normalizeCurrency accepts three letters only', () {
    expect(normalizeCurrency(' eur '), 'EUR');
    expect(normalizeCurrency('EU'), isNull);
    expect(normalizeCurrency('EU1'), isNull);
    expect(normalizeCurrency(''), isNull);
  });

  test('cleanCurrencies drops junk and duplicates, keeping order', () {
    expect(cleanCurrencies(['rsd', 'RUB', 'x', 'RSD']), ['RSD', 'RUB']);
  });

  test('home tabs: listed currencies that have receipts first, then by receipt count', () {
    final receipts = [_in('USD', 'a'), _in('EUR', 'b'), _in('EUR', 'c'), _in('RUB', 'd')];
    // TRY is listed but has no receipts: no empty tab.
    expect(homeCurrencies(receipts, const ['RUB', 'TRY']), ['RUB', 'EUR', 'USD']);
  });

  test('entry currencies: user list first, then the latest receipts newest first', () {
    final receipts = [_in('EUR', 'a'), _in('RUB', 'b'), _in('USD', 'c')];
    expect(entryCurrencies(receipts, const ['USD']), ['USD', 'EUR', 'RUB']);
    expect(entryCurrencies(receipts, const [], recent: 2), ['EUR', 'RUB']);
  });
}
