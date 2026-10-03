final _decimal = RegExp(r'^([+-]?)(\d*)(?:[.,](\d*))?$');

/// Reads "1247.5", "-3", "1247,50" into minor units with [exp] fraction digits.
/// Extra digits round half away from zero. Integer arithmetic only.
/// Null when [raw] is not a plain decimal number.
int? parseMinor(String raw, int exp) {
  final match = _decimal.firstMatch(raw.trim());
  if (match == null) return null;
  final whole = match[2]!;
  var frac = match[3] ?? '';
  if (whole.isEmpty && frac.isEmpty) return null;
  var roundUp = false;
  if (frac.length > exp) {
    roundUp = frac.codeUnitAt(exp) >= 0x35; // '5'
    frac = frac.substring(0, exp);
  }
  final digits = '${whole.isEmpty ? '0' : whole}${frac.padRight(exp, '0')}';
  var value = int.parse(digits) + (roundUp ? 1 : 0);
  if (match[1] == '-') value = -value;
  return value;
}

/// Moves [value] from [fromScale] to [toScale] decimal digits, rounding half away
/// from zero when digits are dropped.
int rescaleMinor(int value, int fromScale, int toScale) {
  var result = value;
  for (var scale = fromScale; scale < toScale; scale++) {
    result *= 10;
  }
  if (fromScale <= toScale) return result;
  var divisor = 1;
  for (var scale = fromScale; scale > toScale; scale--) {
    divisor *= 10;
  }
  final half = divisor ~/ 2;
  return result < 0 ? -((-result + half) ~/ divisor) : (result + half) ~/ divisor;
}

/// Splits [minor] into whole units and the zero-padded fraction for display.
({bool negative, int whole, String fraction}) splitMinor(int minor, int exp) {
  final negative = minor < 0;
  final abs = negative ? -minor : minor;
  var divisor = 1;
  for (var i = 0; i < exp; i++) {
    divisor *= 10;
  }
  final fraction = exp == 0 ? '' : (abs % divisor).toString().padLeft(exp, '0');
  return (negative: negative, whole: abs ~/ divisor, fraction: fraction);
}
