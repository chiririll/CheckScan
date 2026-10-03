import 'name_normalizer.dart';

final _percent = RegExp(r'[0-9]+(?:\.[0-9]+)?%');
final _sized = RegExp(r'[0-9]+(?:\.[0-9]+)?(?:мл|ml|кг|kg|гр|gr|lt|л|l|г|g)', caseSensitive: false);
final _countUnit = RegExp(r'(?<!\p{L})(?:шт|kom|ком|упак|уп|pak|пак)(?!\p{L})', unicode: true, caseSensitive: false);
final _number = RegExp(r'[0-9]+(?:\.[0-9]+)?');
final _spaces = RegExp(r'\s+');
final _dots = RegExp(r'\s*\.\s*');

String itemNameStem(String raw) {
  var text = normalizeItemName(raw);
  text = text.replaceAll(_percent, ' ');
  text = text.replaceAll(_sized, ' ');
  text = text.replaceAll(_countUnit, ' ');
  text = text.replaceAll(_number, ' ');
  text = text.replaceAll(_dots, ' ');
  return text.replaceAll(_spaces, ' ').trim();
}

List<String> stemTokens(String stem) {
  if (stem.isEmpty) return const [];
  return [for (final part in stem.split(' ')) if (part.isNotEmpty) part];
}
