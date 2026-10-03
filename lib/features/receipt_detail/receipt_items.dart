import 'package:eq_models/eq_models.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/format/format.dart';
import '../../core/models/receipt_record.dart';
import '../../l10n/app_localizations.dart';

/// Receipt lines as printed: name, quantity × price, line total.
class ReceiptItemList extends StatelessWidget {
  const ReceiptItemList({super.key, required this.record});

  final ReceiptRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = record.receipt.items;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(),
        Text(l10n.itemsSection, style: AppText.title),
        const SizedBox(height: 8),
        for (final item in items) _ItemRow(item: item, currency: record.currency),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.currency});

  final EqItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description),
                Text(
                  l10n.qtyPrice(formatQty(item.quantity), formatMoney(item.unitPrice, currency)),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(formatMoney(item.totalPrice, currency), style: AppText.title),
        ],
      ),
    );
  }
}
