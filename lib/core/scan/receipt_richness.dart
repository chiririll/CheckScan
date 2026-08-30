import 'package:eq_models/eq_models.dart';

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

/// Incoming data replaces the stored receipt only when it adds real fields:
/// items, merchant, tax id, or a total that the current row does not have.
bool isSignificantlyRicher(EqReceipt incoming, EqReceipt current) {
  if (incoming.items.length > current.items.length) return true;
  if (_hasText(incoming.merchantName) && !_hasText(current.merchantName)) return true;
  if (_hasText(incoming.taxId) && !_hasText(current.taxId)) return true;
  if (incoming.grandTotal > 0 && current.grandTotal == 0) return true;
  return false;
}
