import 'name_normalizer.dart';

final _serviceHints = [
  'билет',
  'проезд',
  'dopuna',
  'prepaid',
  'доставка',
  'dostava',
  'naknada',
  'маршрут',
];

final _routeLike = RegExp(r'.+-.+/.+', unicode: true);

bool looksLikeService(String raw) {
  final folded = normalizeItemName(raw);
  if (_serviceHints.any(folded.contains)) return true;
  return _routeLike.hasMatch(raw);
}
