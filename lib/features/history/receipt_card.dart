import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/models/receipt_record.dart';
import '../../l10n/app_localizations.dart';
import '../receipt_detail/receipt_page.dart';

class ReceiptCard extends StatelessWidget {
  const ReceiptCard({super.key, required this.receipt, required this.state});

  final ReceiptRecord receipt;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = receipt.merchantName?.isNotEmpty == true ? receipt.merchantName! : l10n.receiptTitle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE4E4E4)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => ReceiptPage(state: state, receiptId: receipt.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    if (receipt.missingRemoteItems) ...[
                      Tooltip(
                        message: l10n.missingItemsHint,
                        child: Icon(Icons.cloud_off, size: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(formatMoney(receipt.grandTotal, receipt.currency), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(l10n.itemsCount(receipt.itemCount), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
