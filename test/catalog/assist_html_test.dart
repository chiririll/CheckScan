import 'package:checkscan/core/catalog/assist/assist_clipboard.dart';
import 'package:checkscan/core/catalog/assist/assist_html.dart';
import 'package:checkscan/core/catalog/assist/assist_parse.dart';
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

const _realLlmHtml = '''
<h3>Фасоль</h3>
<ul>
<li>25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM</li>
</ul>
<h3>Айвар</h3>
<ul>
<li>28011: AJVAR DOMA\uFFFDI LJUTI BA\uFFFD BA\uFFFD 350G/KOM</li>
</ul>
<h3>Печенье</h3>
<ul>
<li>28130: KEKS NOBLICE THINS BANINI 170G/KOM</li>
<li>Biskvit Jaffa 300g/KOM</li>
<li>Jaffa kolaci brownie 75g/KOM</li>
</ul>
''';

const _strippedPlain = '''
Фасоль
25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM
Айвар
28011: AJVAR DOMA\uFFFDI LJUTI BA\uFFFD BA\uFFFD 350G/KOM
Печенье
28130: KEKS NOBLICE THINS BANINI 170G/KOM
Biskvit Jaffa 300g/KOM
Jaffa kolaci brownie 75g/KOM
''';

void _expectRealLlmGroups(AssistParsedReply parsed) {
  expect(parsed.groups.map((group) => group.productName), ['Фасоль', 'Айвар', 'Печенье']);
  expect(parsed.groups[0].lines.single, '25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM');
  expect(parsed.groups[1].lines.single, '28011: AJVAR DOMA\uFFFDI LJUTI BA\uFFFD BA\uFFFD 350G/KOM');
  expect(parsed.groups[2].lines, [
    '28130: KEKS NOBLICE THINS BANINI 170G/KOM',
    'Biskvit Jaffa 300g/KOM',
    'Jaffa kolaci brownie 75g/KOM',
  ]);
}

void main() {
  test('HTML tags rebuild prefixes; clipboard HTML has no ### or *', () {
    expect(_realLlmHtml, isNot(contains('###')));
    expect(_realLlmHtml, isNot(contains('*')));
    final converted = assistHtmlToPrefixed(_realLlmHtml);
    expect(assistFirstPrefixType(converted), '#');
    _expectRealLlmGroups(parseAssistReply(converted));
  });

  test('HTML paste resolves to the same 3-product shape as markdown', () {
    final text = resolveAssistPasteText(const AssistClipData(plain: _strippedPlain, html: _realLlmHtml));
    expect(text, isNot(equals(_strippedPlain)));
    _expectRealLlmGroups(parseAssistReply(text));
    _expectRealLlmGroups(parseAssistReply(_realLlmReply));
  });

  test('p>strong is a heading family, li is the other', () {
    const html = '''
<p><strong>Фасоль</strong></p>
<ul><li>25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM</li></ul>
''';
    expect(html, isNot(contains('###')));
    final converted = assistHtmlToPrefixed(html);
    expect(assistFirstPrefixType(converted), '#');
    final parsed = parseAssistReply(converted);
    expect(parsed.groups.single.productName, 'Фасоль');
    expect(parsed.groups.single.lines.single, '25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM');
  });

  test('plain markdown still works when that is what was copied', () {
    final text = resolveAssistPasteText(const AssistClipData(plain: _realLlmReply));
    expect(text, _realLlmReply);
    _expectRealLlmGroups(parseAssistReply(text));
  });

  test('stripped plain without prefixes does not invent groups', () {
    expect(parseAssistReply(_strippedPlain).groups, isEmpty);
    final text = resolveAssistPasteText(const AssistClipData(plain: _strippedPlain));
    expect(text, _strippedPlain);
    expect(parseAssistReply(text).groups, isEmpty);
  });

  test('confirm path prefers HTML structure over a stripped field', () {
    final text = resolveAssistPasteText(
      const AssistClipData(plain: _strippedPlain, html: _realLlmHtml),
      fieldText: _strippedPlain,
    );
    _expectRealLlmGroups(parseAssistReply(text));
  });

  test('confirm path keeps typed markdown when HTML is absent', () {
    final text = resolveAssistPasteText(const AssistClipData(), fieldText: _realLlmReply);
    _expectRealLlmGroups(parseAssistReply(text));
  });
}
