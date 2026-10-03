import '../model/item_unit.dart';

class ParsedUnit {
  const ParsedUnit({required this.unit, this.size});

  final ItemUnit unit;
  final double? size;
}

/// Pack size only with a measure unit next to the number (л/мл/кг/г).
final _sized = RegExp(
  r'([0-9]+(?:[.,][0-9]+)?)\s*[x×*]?\s*(мл|ml|кг|kg|гр|gr|lt|л|l|г|g)(?!\p{L}|[%0-9])',
  caseSensitive: false,
  unicode: true,
);

final _piece = RegExp(
  r'(?<!\p{L})(шт\.?|kom\.?|ком)(?!\p{L})',
  caseSensitive: false,
  unicode: true,
);

final _pack = RegExp(
  r'(?<!\p{L})(упак|уп\.?|pak\.?|пак)(?!\p{L})',
  caseSensitive: false,
  unicode: true,
);

ParsedUnit? parseItemUnit(String raw) {
  final text = _normalizeSpaces(raw.toLowerCase());
  final sized = _lastMatch(_sized, text);
  if (sized != null) {
    final unit = _unitFromSuffix(sized[2]!);
    if (unit != null) {
      return ParsedUnit(unit: unit, size: _parseSize(sized[1]!));
    }
  }
  if (_piece.hasMatch(text)) return const ParsedUnit(unit: ItemUnit.piece);
  if (_pack.hasMatch(text)) return const ParsedUnit(unit: ItemUnit.pack);
  return null;
}

String _normalizeSpaces(String raw) => raw.replaceAll(RegExp(r'[\u00a0\u202f\u2007\u2009]'), ' ');

RegExpMatch? _lastMatch(RegExp pattern, String text) {
  RegExpMatch? last;
  for (final match in pattern.allMatches(text)) {
    last = match;
  }
  return last;
}

double _parseSize(String raw) => double.parse(raw.replaceAll(',', '.'));

ItemUnit? _unitFromSuffix(String suffix) {
  return switch (suffix.toLowerCase()) {
    'мл' || 'ml' => ItemUnit.ml,
    'кг' || 'kg' => ItemUnit.kg,
    'л' || 'l' || 'lt' => ItemUnit.l,
    'г' || 'g' || 'гр' || 'gr' => ItemUnit.g,
    _ => null,
  };
}
