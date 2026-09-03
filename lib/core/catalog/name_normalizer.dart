final _keep = RegExp(r'[\p{L}0-9.%]', unicode: true);
final _numberThenUnit = RegExp(r'([0-9]+(?:\.[0-9]+)?)\s+(мл|кг|шт|л|г|уп)');

String normalizeItemName(String raw) {
  final lower = raw.toLowerCase();
  final buf = StringBuffer();
  var prevSpace = true;
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    if (ch == ',') {
      buf.write('.');
      prevSpace = false;
      continue;
    }
    if (_keep.hasMatch(ch)) {
      buf.write(ch);
      prevSpace = false;
      continue;
    }
    if (!prevSpace) {
      buf.write(' ');
      prevSpace = true;
    }
  }
  return buf.toString().trim().replaceAllMapped(_numberThenUnit, (m) => '${m[1]}${m[2]}');
}

String tagNameKey(String name) => name.trim().toLowerCase();
