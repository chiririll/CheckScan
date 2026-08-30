import 'package:adapter_eq_payload/adapter_eq_payload.dart';
import 'package:adapter_ru_fns/adapter_ru_fns.dart';
import 'package:checkscan/core/scan/adapter_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fns = 't=20260828T1842&s=1247.00&fn=8710000100905518&i=12&fp=4135164163&n=1';
  const fnsUrl = 'https://consumer.1-ofd.ru/ticket?t=20260828T1842&s=1247.00&fn=8710000100905518&i=12&fp=4135164163&n=1';
  const eqJson = '''
{"eq_version":"1.0.0","receipt":{"id":"550e8400-e29b-41d4-a716-446655440000","issued_at":"2026-08-28T18:42:00+03:00","currency":"RUB","receipt_type":"sale","merchant":{"name":"Пятёрочка"},"items":[{"description":"Молоко 1 л","quantity":2,"unit_price":89,"total_price":178}],"totals":{"grand_total":1247}}}
''';

  final chain = AdapterChain();

  test('ru_fns recognizes query and url with same hash', () {
    const adapter = RuFnsAdapter();
    expect(adapter.canHandle(fns), '8710000100905518|12|4135164163');
    expect(adapter.canHandle(fnsUrl), adapter.canHandle(fns));
    expect(adapter.canHandle('hello'), isNull);
  });

  test('eq_payload recognizes eQ json by receipt id', () {
    const adapter = EqPayloadAdapter();
    expect(adapter.canHandle(eqJson), '550e8400-e29b-41d4-a716-446655440000');
    expect(adapter.canHandle(fns), isNull);
  });

  test('chain prefers eq_payload then ru_fns', () {
    expect(chain.match(eqJson)?.adapter.id, 'eq_payload');
    expect(chain.match(fns)?.adapter.id, 'ru_fns');
    expect(chain.match('not-a-receipt'), isNull);
    expect(chain.match(fns)?.storageKey, 'ru_fns:8710000100905518|12|4135164163');
  });

  test('ru_fns parse fills total without items', () async {
    const adapter = RuFnsAdapter();
    final receipt = await adapter.parse(fns);
    expect(receipt.grandTotal, 1247);
    expect(receipt.items, isEmpty);
    expect(receipt.currency, 'RUB');
  });
}
