import 'package:sqflite/sqflite.dart';

import '../../models/receipt_record.dart';
import '../../storage/row.dart';
import '../catalog_resolver.dart';
import '../model/purchase.dart';
import 'catalog_tables.dart';

/// `purchase` is a cache: one row per receipt and catalog product.
mixin PurchaseTable on CatalogTables {
  Future<List<Purchase>> listPurchases() async {
    final rows = await (await db).rawQuery('''
      SELECT p.id, p.check_id, p.product_id, p.quantity, p.unit_price, p.total,
             r.issued_at, r.scanned_at, r.currency, r.merchant_id, r.merchant_name
      FROM purchase p
      JOIN receipts r ON r.id = p.check_id
    ''');
    return [
      for (final row in rows)
        Purchase(
          id: row.str('id'),
          checkId: row.str('check_id'),
          productId: row.str('product_id'),
          quantity: row.optDouble('quantity') ?? 0,
          unitPrice: row.optDouble('unit_price') ?? 0,
          total: row.optDouble('total') ?? 0,
          currency: row.str('currency'),
          issuedAt: row.date('issued_at'),
          scannedAt: row.date('scanned_at'),
          merchantId: row.optStr('merchant_id'),
          merchantName: row.optStr('merchant_name'),
        ),
    ];
  }

  /// Rewrites the cache. Receipts of [ignoreMerchantIds] contribute nothing.
  Future<void> writePurchases({
    required List<ReceiptRecord> receipts,
    required CatalogResolver resolver,
    required Set<String> ignoreMerchantIds,
  }) async {
    await (await db).transaction((txn) async {
      await txn.delete('purchase');
      for (final receipt in receipts) {
        if (ignoreMerchantIds.contains(receipt.merchantId)) continue;
        for (final entry in _totalsByProduct(receipt, resolver).entries) {
          final acc = entry.value;
          if (acc.quantity <= 0) continue;
          await txn.insert('purchase', {
            'check_id': receipt.id,
            'product_id': dbId(entry.key),
            'quantity': acc.quantity,
            'unit_price': acc.total / acc.quantity,
            'total': acc.total,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }
}

Map<String, _PurchaseAcc> _totalsByProduct(ReceiptRecord receipt, CatalogResolver resolver) {
  final totals = <String, _PurchaseAcc>{};
  for (final line in receipt.receipt.items) {
    final productId = resolver.resolve(line.description)?.product?.id;
    if (productId == null) continue;
    final acc = totals.putIfAbsent(productId, _PurchaseAcc.new);
    acc.quantity += line.quantity;
    acc.total += line.totalPrice;
  }
  return totals;
}

class _PurchaseAcc {
  double quantity = 0;
  double total = 0;
}
