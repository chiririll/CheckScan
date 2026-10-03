import '../models/receipt_record.dart';

final _code = RegExp(r'^[A-Z]{3}$');

/// "eur " → "EUR"; null when [raw] is not a three-letter code.
String? normalizeCurrency(String raw) {
  final code = raw.trim().toUpperCase();
  return _code.hasMatch(code) ? code : null;
}

/// Valid codes of [raw], upper-cased, first occurrence wins.
List<String> cleanCurrencies(Iterable<String> raw) {
  final seen = <String>{};
  return [
    for (final item in raw)
      if (normalizeCurrency(item) case final code? when seen.add(code)) code,
  ];
}

/// Currencies of the latest [recent] receipts, newest first. [receipts] come newest first.
List<String> recentCurrencies(List<ReceiptRecord> receipts, {int recent = 50}) {
  return cleanCurrencies(receipts.take(recent).map((receipt) => receipt.currency));
}

/// Home tabs: currencies that have receipts. The user's [order] goes first; the rest follow by receipt count.
List<String> homeCurrencies(List<ReceiptRecord> receipts, List<String> order) {
  final counts = <String, int>{};
  for (final receipt in receipts) {
    final code = normalizeCurrency(receipt.currency);
    if (code != null) counts[code] = (counts[code] ?? 0) + 1;
  }
  final listed = cleanCurrencies(order).where(counts.containsKey);
  final rest = counts.keys.where((code) => !listed.contains(code)).toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!) != 0 ? counts[b]!.compareTo(counts[a]!) : a.compareTo(b));
  return [...listed, ...rest];
}

/// Currencies a new receipt can be entered in: the user's [order], then those of the latest receipts.
List<String> entryCurrencies(List<ReceiptRecord> receipts, List<String> order, {int recent = 50}) {
  return cleanCurrencies([...order, ...recentCurrencies(receipts, recent: recent)]);
}
