import 'package:intl/intl.dart';

final _money = NumberFormat.decimalPattern('ru');
final _day = DateFormat('d MMMM', 'ru');
final _dayYear = DateFormat('d MMMM y', 'ru');
final _dateTime = DateFormat('d MMMM y, HH:mm', 'ru');
final _time = DateFormat('HH:mm');

String formatMoney(double value, [String currency = 'RUB']) {
  final amount = _money.format(value);
  if (currency == 'RUB') return '$amount ₽';
  return '$amount $currency';
}

String formatDayHeader(DateTime date) => _dayYear.format(date);

String formatDayShort(DateTime date) => _day.format(date);

String formatDateTime(DateTime date) => _dateTime.format(date);

String formatTime(DateTime date) => _time.format(date);

String formatQty(double qty) {
  if (qty == qty.roundToDouble()) return qty.toInt().toString();
  return qty.toString();
}
