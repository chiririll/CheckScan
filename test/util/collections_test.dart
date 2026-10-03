import 'package:checkscan/core/util/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('firstWhereOrNull returns the first match or null', () {
    expect([1, 2, 3, 4].firstWhereOrNull((n) => n.isEven), 2);
    expect([1, 3].firstWhereOrNull((n) => n.isEven), isNull);
  });

  test('groupBy keeps first-seen group order and item order', () {
    final groups = ['bb', 'a', 'cc', 'd'].groupBy((s) => s.length);
    expect(groups.keys, [2, 1]);
    expect(groups[2], ['bb', 'cc']);
    expect(groups[1], ['a', 'd']);
  });

  test('trimmedOrNull drops blank strings', () {
    expect(trimmedOrNull(null), isNull);
    expect(trimmedOrNull('   '), isNull);
    expect(trimmedOrNull(' ИНН 1 '), 'ИНН 1');
  });
}
