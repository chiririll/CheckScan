import 'package:checkscan/core/catalog/assist_parse.dart';
import 'package:flutter_test/flutter_test.dart';

const _markdown = '''
### Фасоль

* 25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM

### Айвар

* 28011: AJVAR DOMAĆI LJUTI BAČ BAČ 350G/KOM

### Печенье

* 28130: KEKS NOBLICE THINS BANINI 170G/KOM
* Biskvit Jaffa 300g/KOM
''';

const _plain = '''
Фасоль
25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM

Айвар
    28011: AJVAR DOMAĆI LJUTI BAČ BAČ 350G/KOM

Печенье
28130: KEKS NOBLICE THINS BANINI 170G/KOM
Biskvit Jaffa 300g/KOM
''';

void main() {
  test('groups heading/bullets and the same text without markdown marks', () {
    final marked = parseAssistReply(_markdown);
    final plain = parseAssistReply(_plain);
    expect(marked.groups.map((group) => group.productName), ['Фасоль', 'Айвар', 'Печенье']);
    expect(plain.groups.map((group) => group.productName), ['Фасоль', 'Айвар', 'Печенье']);
    expect(marked.groups[0].lines.single, contains('PASULJ CRVENI'));
    expect(plain.groups[0].lines.single, contains('PASULJ CRVENI'));
    expect(marked.groups[2].lines, hasLength(2));
    expect(plain.groups[2].lines, hasLength(2));
    expect(plain.groups[2].lines.last, contains('Biskvit Jaffa'));
  });

  test('does not require markdown heading or bullet characters', () {
    expect(_plain, isNot(contains('###')));
    expect(_plain, isNot(contains('*')));
    final parsed = parseAssistReply(_plain);
    expect(parsed.groups, isNotEmpty);
    expect(cleanAssistLine('### Фасоль'), 'Фасоль');
    expect(cleanAssistLine('* 25016: PASULJ'), '25016: PASULJ');
    expect(looksLikeProductTitle('Фасоль'), isTrue);
    expect(looksLikePositionLine('PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM'), isTrue);
  });

  test('skips preamble and still reads a Товар label', () {
    const raw = '''
Вот результат без пояснений.

Товар: Фасоль
25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM
''';
    final parsed = parseAssistReply(raw);
    expect(parsed.groups.single.productName, 'Фасоль');
    expect(parsed.groups.single.lines.single, contains('PASULJ'));
  });

  test('accepts a trivial products JSON list', () {
    const raw = '''
{"products":[{"name":"Фасоль","positions":[{"id":"12","name":"PASULJ CRVENI 400G"}]}]}
''';
    final parsed = parseAssistReply(raw);
    expect(parsed.groups.single.productName, 'Фасоль');
    expect(parsed.groups.single.lines.single, '12: PASULJ CRVENI 400G');
  });

  test('empty products JSON is not a grouping', () {
    expect(parseAssistReply('{"products":[]}').groups, isEmpty);
    expect(parseAssistReply('просто текст без товаров').groups, isEmpty);
  });
}
