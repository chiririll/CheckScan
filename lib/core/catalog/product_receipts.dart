import '../models/receipt_record.dart';
import 'model/purchase.dart';

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
  return [for (final receipt in receipts) if (ids.contains(receipt.id)) receipt]
    ..sort((a, b) => b.at.compareTo(a.at));
}
