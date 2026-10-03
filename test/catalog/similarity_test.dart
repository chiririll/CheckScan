import 'package:checkscan/core/catalog/text/similarity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('levenshtein counts single edits', () {
    expect(levenshtein('молоко', 'молоко'), 0);
    expect(levenshtein('', 'abc'), 3);
    expect(levenshtein('kitten', 'sitting'), 3);
  });

  test('editRatio is the distance share of the longer string', () {
    expect(editRatio('abcd', 'abcd'), 0);
    expect(editRatio('abcd', 'abce'), 0.25);
    expect(editRatio('', ''), 0);
  });

  test('isEditClose accepts either an absolute or a relative bound', () {
    expect(isEditClose('кефир', 'кефер', maxEdits: 1, maxRatio: 0), isTrue);
    expect(isEditClose('abcdefghij', 'abcdefghxy', maxEdits: 1, maxRatio: 0.2), isTrue);
    expect(isEditClose('хлеб', 'сыр', maxEdits: 1, maxRatio: 0.25), isFalse);
  });
}
