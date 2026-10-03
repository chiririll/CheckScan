/// ISO 4217 exponents that differ from the default of 2.
const _minorDigits = {
  'JPY': 0,
  'KRW': 0,
  'VND': 0,
  'BHD': 3,
  'KWD': 3,
  'OMR': 3,
  'TND': 3,
};

/// Decimal digits of the currency's minor unit (RUB, RSD: 2).
int minorExponent(String currency) => _minorDigits[currency.toUpperCase()] ?? 2;

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
