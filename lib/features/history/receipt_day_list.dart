import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/export/export_file.dart';
import '../../core/format/format.dart';
import '../../core/models/receipt_record.dart';
import '../../core/state/app_state.dart';
import '../../core/util/collections.dart';
import 'receipt_card.dart';

/// Receipts under day headers, in the given order.
class ReceiptDayList extends StatelessWidget {
  const ReceiptDayList({super.key, required this.state, required this.receipts});

  final AppState state;
  final List<ReceiptRecord> receipts;

  @override
  Widget build(BuildContext context) {
    final days = receipts.groupBy((receipt) => isoDate(receipt.at));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final dayReceipts in days.values) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 8),
            child: Text(formatDayHeader(dayReceipts.first.at), style: AppText.mutedSmall),
          ),
          for (final receipt in dayReceipts) ReceiptCard(receipt: receipt, state: state),
        ],
      ],
    );
  }
}
