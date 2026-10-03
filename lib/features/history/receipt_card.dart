import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/format/format.dart';
import '../../core/models/receipt_record.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../receipt_detail/receipt_page.dart';
import '../widgets/navigation.dart';

class ReceiptCard extends StatelessWidget {
  const ReceiptCard({super.key, required this.receipt, required this.state});

  final ReceiptRecord receipt;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        shape: AppShapes.card,
        child: InkWell(
          borderRadius: AppShapes.radius,
          onTap: () => pushPage<void>(context, ReceiptPage(state: state, receiptId: receipt.id)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        receipt.displayMerchant(l10n.receiptTitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title,
                      ),
                    ),
                    if (receipt.missingRemoteItems) ...[
                      Tooltip(
                        message: l10n.missingItemsHint,
                        child: const Icon(Icons.cloud_off, size: 16, color: AppColors.muted),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(formatMoney(receipt.grandTotal, receipt.currency), style: AppText.title),
                  ],
                ),
                const SizedBox(height: 2),
                Text(l10n.itemsCount(receipt.itemCount), style: AppText.mutedSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
