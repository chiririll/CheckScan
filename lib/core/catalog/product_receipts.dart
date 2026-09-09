import '../models/receipt_record.dart';
import 'purchase.dart';

/// Receipts that contain a catalog product via `purchase` links, newest first.
List<ReceiptRecord> receiptsContainingProduct({
  required Iterable<Purchase> purchases,
  required Iterable<ReceiptRecord> receipts,
  required String productId,
}) {
  final ids = {
    for (final purchase in purchases)
      if (purchase.productId == productId) purchase.checkId,
  };
  if (ids.isEmpty) return const [];
  final found = [for (final receipt in receipts) if (ids.contains(receipt.id)) receipt];
  found.sort((a, b) {
    return (b.issuedAt ?? b.scannedAt).compareTo(a.issuedAt ?? a.scannedAt);
  });
  return found;
}
