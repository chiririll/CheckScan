import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/models/receipt_record.dart';
import '../../l10n/app_localizations.dart';
import '../receipt_detail/receipt_page.dart';
import '../widgets/empty_hint.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groups = <String, List<ReceiptRecord>>{};
    for (final receipt in state.receipts) {
      final date = receipt.issuedAt ?? receipt.scannedAt;
      final key = DateFormat('yyyy-MM-dd').format(date);
      groups.putIfAbsent(key, () => []).add(receipt);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: state.receipts.isEmpty
          ? EmptyHint(title: l10n.emptyHistoryTitle, body: l10n.emptyHistoryBody)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, top: 8),
                    child: Text(
                      formatDayHeader(DateTime.parse(entry.key)),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                  ...entry.value.map((receipt) => _Card(receipt: receipt, state: state)),
                ],
              ],
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.receipt, required this.state});

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
            MaterialPageRoute(builder: (_) => ReceiptPage(state: state, receiptId: receipt.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
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
