import 'item_unit.dart';

class ParsedUnit {
  const ParsedUnit({required this.unit, this.size});

  final ItemUnit unit;
  final double? size;
}

final _sized = RegExp(
  r'([0-9]+(?:[.,][0-9]+)?)\s*(миллилитр(?:ов|а)?|мл|литров|литра|литр|л|килограмм(?:ов|а)?|кг|граммов|грамм|гр|г)(?![а-яa-z%0-9])',
  caseSensitive: false,
);

final _piece = RegExp(r'(?<![а-яa-z])(штук|шт\.?|шт)(?![а-яa-z])', caseSensitive: false);

final _pack = RegExp(r'(?<![а-яa-z])(упаковка|упак|уп)(?![а-яa-z])', caseSensitive: false);

ParsedUnit? parseItemUnit(String raw) {
  final text = raw.toLowerCase();
  final sized = _sized.firstMatch(text);
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

double _parseSize(String raw) => double.parse(raw.replaceAll(',', '.'));

ItemUnit? _unitFromSuffix(String suffix) {
  final s = suffix.toLowerCase();
  if (s.startsWith('мл') || s.startsWith('миллилитр')) return ItemUnit.ml;
  if (s.startsWith('л') || s.startsWith('литр')) return ItemUnit.l;
  if (s.startsWith('кг') || s.startsWith('килограмм')) return ItemUnit.kg;
  if (s.startsWith('г')) return ItemUnit.g;
  return null;
}
