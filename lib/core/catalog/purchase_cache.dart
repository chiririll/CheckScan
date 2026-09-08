import 'package:sqflite/sqflite.dart';

import '../merchant/merchant.dart';
import '../models/receipt_record.dart';
import 'catalog_resolver.dart';

Future<void> rebuildPurchaseCache({
  required DatabaseExecutor db,
  required List<ReceiptRecord> receipts,
  required CatalogResolver resolver,
  required Set<String> ignoreMerchantIds,
}) async {
  await db.delete('purchase');
  for (final receipt in receipts) {
    final merchantId = receipt.merchantId;
    if (merchantId != null && ignoreMerchantIds.contains(merchantId)) continue;
    final totals = <String, _PurchaseAcc>{};
    for (final line in receipt.receipt.items) {
      final hit = resolver.resolve(line.description);
      final productId = hit?.product?.id;
      if (productId == null) continue;
      final acc = totals.putIfAbsent(productId, _PurchaseAcc.new);
      acc.quantity += line.quantity;
      acc.total += line.totalPrice;
    }
    for (final entry in totals.entries) {
      final acc = entry.value;
      if (acc.quantity <= 0) continue;
      await db.insert('purchase', {
        'check_id': receipt.id,
        'product_id': int.parse(entry.key),
        'quantity': acc.quantity,
        'unit_price': acc.total / acc.quantity,
        'total': acc.total,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}

class _PurchaseAcc {
  double quantity = 0;
  double total = 0;
}

Set<String> ignoreMerchantIdsOf(Iterable<Merchant> merchants) {
  return {for (final merchant in merchants) if (merchant.ignoresItems) merchant.id};
}
