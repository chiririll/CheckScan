import 'package:checkscan/core/catalog/assist_draft.dart';
import 'package:checkscan/core/catalog/assist_match.dart';
import 'package:checkscan/core/catalog/assist_parse.dart';
import 'package:checkscan/core/catalog/catalog_position.dart';
import 'package:flutter_test/flutter_test.dart';

const _beans = CatalogPosition(
  id: '1',
  displayName: 'PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM',
);
const _cookies = CatalogPosition(
  id: '2',
  displayName: 'KEKS NOBLICE THINS BANINI 170G/KOM',
);
const _ajvar = CatalogPosition(
  id: '3',
  displayName: 'AJVAR DOMAĆI LJUTI BAČ BAČ 350G/KOM',
);

void main() {
  test('prefers the closest unassigned name', () {
    final hit = matchAssistLine('KEKS NOBLICE THINS BANINI 170G/KOM', [_beans, _cookies, _ajvar]);
    expect(hit!.position.id, '2');
    expect(hit.confidence, greaterThanOrEqualTo(assistMatchMinConfidence));
  });

  test('exact mismatch still hits a shortened cashier string', () {
    final hit = matchAssistLine('PASULJ CRVENI 400G', [_beans, _cookies]);
    expect(hit, isNotNull);
    expect(hit!.position.id, '1');
    expect(hit.confidence, greaterThanOrEqualTo(assistMatchMinConfidence));
    expect(normalizeAssistName(_beans.displayName), isNot(normalizeAssistName('PASULJ CRVENI 400G')));
  });

  test('low similarity is rejected', () {
    final hit = matchAssistLine('Хлеб дарницкий 0,6кг', [_beans]);
    expect(hit == null || hit.confidence < assistMatchMinConfidence, isTrue);
    final draft = matchAssistGroups(
      const [AssistParsedGroup(productName: 'Хлеб', lines: ['Хлеб дарницкий 0,6кг'])],
      const [_beans],
    );
    expect(draft.products.single.name, 'Хлеб');
    expect(draft.products.single.positions, isEmpty);
    expect(draft.unmatched.single.raw, contains('Хлеб'));
  });

  test('matches a known leading id even when the name differs', () {
    final hit = matchAssistLine('1: completely different text', [_beans, _cookies]);
    expect(hit!.position.id, '1');
    expect(hit.confidence, 1);
  });

  test('cashier id on the position line matches and stays on the stored line', () {
    const beans = CatalogPosition(
      id: '25016',
      displayName: 'PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM',
    );
    const line = '25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM';
    final hit = matchAssistLine(line, const [beans, _cookies]);
    expect(hit!.position.id, '25016');
    expect(hit.confidence, 1);

    final draft = matchAssistGroups(
      const [AssistParsedGroup(productName: 'Фасоль', lines: [line])],
      const [beans],
    );
    expect(draft.products.single.positions.single.rawLine, line);
    expect(draft.products.single.positions.single.rawLine, contains('25016:'));
    expect(draft.products.single.positions.single.displayName, beans.displayName);
  });

  test('one item is not assigned to two products', () {
    final draft = matchAssistGroups(
      const [
        AssistParsedGroup(
          productName: 'Фасоль',
          lines: ['PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM', 'PASULJ CRVENI'],
        ),
        AssistParsedGroup(productName: 'Другое', lines: ['PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM']),
      ],
      const [_beans],
    );
    final assigned = [for (final product in draft.products) for (final position in product.positions) position.positionId];
    expect(assigned.where((id) => id == '1'), hasLength(1));
    expect(draft.products.map((product) => product.name), ['Фасоль', 'Другое']);
    expect(draft.products.first.positions.single.positionId, '1');
    expect(draft.products.last.positions, isEmpty);
    expect(draft.unmatched, isNotEmpty);
  });

  test('reviewAssistReply maps empty and unreadable text to errors', () {
    expect(reviewAssistReply('', const [_beans]).error, AssistParseError.empty);
    expect(reviewAssistReply('просто пояснение без товаров', const [_beans]).error, AssistParseError.noProducts);
  });

  test('reviewAssistReply opens draft when parse has groups even if nothing matches', () {
    const raw = '''
### Фасоль

* 25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM

### Айвар

* 28011: AJVAR DOMA\uFFFDI LJUTI BA\uFFFD BA\uFFFD 350G/KOM

### Печенье

* 28130: KEKS NOBLICE THINS BANINI 170G/KOM
* Biskvit Jaffa 300g/KOM
* Jaffa kolaci brownie 75g/KOM
''';
    final miss = reviewAssistReply(raw, const []);
    expect(miss.error, isNull);
    expect(miss.draft!.products.map((product) => product.name), ['Фасоль', 'Айвар', 'Печенье']);
    expect(miss.draft!.canApply, isFalse);
    expect(miss.draft!.unmatched, hasLength(5));

    final hit = reviewAssistReply(raw, const [_beans, _cookies, _ajvar]);
    expect(hit.error, isNull);
    expect(hit.draft!.canApply, isTrue);
    expect(hit.draft!.products.map((product) => product.name), ['Фасоль', 'Айвар', 'Печенье']);
  });
}
