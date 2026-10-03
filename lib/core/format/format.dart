import 'package:intl/intl.dart';
import 'package:receipt_model/receipt_model.dart';

final _grouped = NumberFormat.decimalPattern('ru');
final _dayYear = DateFormat('d MMMM y', 'ru');
final _monthYear = DateFormat('LLLL y', 'ru');
final _dateTime = DateFormat('d MMMM y, HH:mm', 'ru');

const _currencySymbols = {'RUB': '₽', 'RSD': 'дин.'};

/// [minor] is in the currency's minor units. Whole amounts drop the fraction: "1 247 ₽", "178,50 ₽".
String formatMoney(int minor, [String currency = 'RUB']) {
  final parts = splitMinor(minor, minorExponent(currency));
  final whole = _grouped.format(parts.whole);
  final hasFraction = parts.fraction.isNotEmpty && int.parse(parts.fraction) != 0;
  final amount = hasFraction ? '$whole,${parts.fraction}' : whole;
  return '${parts.negative ? '-' : ''}$amount ${formatCurrencyLabel(currency)}';
}

String formatCurrencyLabel(String currency) => _currencySymbols[currency] ?? currency;

String formatMonthYear(DateTime date) {
  final raw = _monthYear.format(date);
  if (raw.isEmpty) return raw;
  return '${raw[0].toUpperCase()}${raw.substring(1)}';
}

String formatDayHeader(DateTime date) => _dayYear.format(date);

String formatDateTime(DateTime date) => _dateTime.format(date);

String formatQty(double qty) {
  if (qty == qty.roundToDouble()) return qty.toInt().toString();
  return qty.toString();
}
