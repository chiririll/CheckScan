import 'package:checkscan/core/catalog/assist_parse.dart';
import 'package:flutter_test/flutter_test.dart';

const _realLlmReply = '''
### Фасоль

* 25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM

### Айвар

* 28011: AJVAR DOMA\uFFFDI LJUTI BA\uFFFD BA\uFFFD 350G/KOM

### Печенье

* 28130: KEKS NOBLICE THINS BANINI 170G/KOM
* Biskvit Jaffa 300g/KOM
* Jaffa kolaci brownie 75g/KOM
''';

const _eggsMarkdown = '''
### Яйца
* 28900: JAJA M GRUPE 10/1 BJEKIC/Kom
* JAJA A KLASA L GRUPA 10/ KOM
* JAJA A KLASA M GRUPA 10/ KOM
* Jaja podni uzgoj Maxi 10 1 M/KOM
* Kokos.jaja 10 1 M Maxi/KOM
* СЕЛО ЗЕЛ.Яйцо ДЕРЕВЕНСК.С0 10шт
### Растительное масло
* 27001: ULJE SUNCOKRETOVO 1L/KOM
''';

void _expectRealLlmGroups(AssistParsedReply parsed) {
  expect(parsed.groups.map((group) => group.productName), ['Фасоль', 'Айвар', 'Печенье']);
  expect(parsed.groups[0].lines.single, contains('PASULJ CRVENI'));
  expect(parsed.groups[1].lines.single, contains('AJVAR DOMA'));
  expect(parsed.groups[2].lines, [
    '28130: KEKS NOBLICE THINS BANINI 170G/KOM',
    'Biskvit Jaffa 300g/KOM',
    'Jaffa kolaci brownie 75g/KOM',
  ]);
}

void main() {
  test('real LLM markdown with blank lines is three products', () {
    expect(assistLinePrefix('### Фасоль')?.type, '#');
    expect(assistLinePrefix('* 25016: PASULJ')?.type, '*');
    expect(assistLinePrefix('25016: PASULJ CRVENI'), isNull);
    _expectRealLlmGroups(parseAssistReply(_realLlmReply));
    _expectRealLlmGroups(parseAssistReply('  \n$_realLlmReply\n  '));
    _expectRealLlmGroups(parseAssistReply(_realLlmReply.replaceAll('\n', '\r\n')));
    _expectRealLlmGroups(parseAssistReply(_realLlmReply.replaceAll('\n', '\r')));
  });

  test('first markdown heading type is product, other prefix is position', () {
    const kokos = 'Kokos.jaja 10 1 M Maxi/KOM';
    final parsed = parseAssistReply(_eggsMarkdown);
    expect(parsed.groups.map((group) => group.productName), ['Яйца', 'Растительное масло']);
    expect(parsed.groups[0].lines, hasLength(6));
    expect(parsed.groups[0].lines, contains(kokos));
    expect(parsed.groups[1].lines.single, contains('ULJE SUNCOKRETOVO'));
    expect(assistLinePrefix('### Яйца')?.type, '#');
    expect(assistLinePrefix('* $kokos')?.type, '*');
  });

  test('generic pair Товар: vs dash is two prefix types', () {
    const raw = '''
Товар: Фасоль
- 25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM
Товар: Айвар
- 28011: AJVAR DOMAĆI LJUTI BAČ BAČ 350G/KOM
''';
    expect(assistLinePrefix('Товар: Фасоль')?.type, ':');
    expect(assistLinePrefix('- 25016: PASULJ')?.type, '-');
    final parsed = parseAssistReply(raw);
    expect(parsed.groups.map((group) => group.productName), ['Фасоль', 'Айвар']);
    expect(parsed.groups[0].lines.single, contains('PASULJ CRVENI'));
    expect(parsed.groups[1].lines.single, contains('AJVAR'));
  });

  test('first prefix wins when stars are titles and hashes are items', () {
    const raw = '''
* Яйца
### 28900: JAJA M GRUPE 10/1 BJEKIC/Kom
### Kokos.jaja 10 1 M Maxi/KOM
* Растительное масло
### 27001: ULJE SUNCOKRETOVO 1L/KOM
''';
    final parsed = parseAssistReply(raw);
    expect(parsed.groups.map((group) => group.productName), ['Яйца', 'Растительное масло']);
    expect(parsed.groups[0].lines, contains('Kokos.jaja 10 1 M Maxi/KOM'));
    expect(parsed.groups[1].lines.single, contains('ULJE SUNCOKRETOVO'));
  });

  test('preamble before the first prefixed line is ignored', () {
    const raw = '''
Вот результат без пояснений.
Ниже группировка как получилось.

### Яйца
* 28900: JAJA M GRUPE 10/1 BJEKIC/Kom
''';
    final parsed = parseAssistReply(raw);
    expect(parsed.groups.single.productName, 'Яйца');
    expect(parsed.groups.single.lines.single, contains('JAJA M GRUPE'));
  });

  test('empty or no prefixes yields no groups', () {
    expect(parseAssistReply('').groups, isEmpty);
    expect(parseAssistReply('просто текст без товаров').groups, isEmpty);
    expect(parseAssistReply('{"products":[]}').groups, isEmpty);
  });

  test('empty JSON preamble does not swallow markdown groups', () {
    final parsed = parseAssistReply('{"products":[]}\n$_realLlmReply');
    _expectRealLlmGroups(parsed);
  });

  test('accepts a trivial products JSON list', () {
    const raw = '''
{"products":[{"name":"Фасоль","positions":[{"id":"12","name":"PASULJ CRVENI 400G"}]}]}
''';
    final parsed = parseAssistReply(raw);
    expect(parsed.groups.single.productName, 'Фасоль');
    expect(parsed.groups.single.lines.single, '12: PASULJ CRVENI 400G');
  });
}
