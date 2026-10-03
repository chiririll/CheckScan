import 'package:receipt_model/receipt_model.dart';

import '../../core/merchant/merchant.dart';
import '../../core/models/receipt_record.dart';
import 'home_period.dart';

class MerchantTeaser {
  const MerchantTeaser({required this.total, required this.withoutNetwork});

  factory MerchantTeaser.of(List<Merchant> merchants) {
    final parents = {for (final merchant in merchants) ?merchant.parentId};
    return MerchantTeaser(
      total: merchants.length,
      withoutNetwork: merchants.where((m) => m.parentId == null && !parents.contains(m.id)).length,
    );
  }

  final int total;

  /// Stores that are neither in a network nor a network themselves.
  final int withoutNetwork;

  bool get isEmpty => total == 0;
}

/// Home screen figures for one month and one currency.
class HomeDashboard {
  const HomeDashboard({
    required this.spent,
    required this.spentScale,
    required this.receiptCount,
    required this.merchants,
  });

  factory HomeDashboard.of({
    required List<ReceiptRecord> receipts,
    required List<Merchant> merchants,
    required HomePeriod period,
    required String currency,
  }) {
    final scoped = [
      for (final receipt in receipts)
        if (receipt.currency == currency && period.contains(receipt.at)) receipt,
    ];
    // Providers of one currency may differ in precision: sum at the finest scale.
    final scale = scoped.fold<int>(0, (finest, receipt) => receipt.scale > finest ? receipt.scale : finest);
    return HomeDashboard(
      spent: scoped.fold<int>(0, (sum, receipt) => sum + rescaleMinor(receipt.signedTotal, receipt.scale, scale)),
      spentScale: scale,
      receiptCount: scoped.length,
      merchants: MerchantTeaser.of(merchants),
    );
  }

  /// Total of the period, counting 10^-[spentScale] currency units.
  final int spent;
  final int spentScale;
  final int receiptCount;
  final MerchantTeaser merchants;

  bool get isEmpty => receiptCount == 0;
}
