import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/models/receipt_record.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/empty_hint.dart';
import 'receipt_card.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.state});

  final AppState state;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _busy = false;

  AppState get state => widget.state;

  Future<void> _refreshPending() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await state.refreshPending();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).refreshPendingDone)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).parseErrorBody)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groups = <String, List<ReceiptRecord>>{};
    for (final receipt in state.receipts) {
      final date = receipt.issuedAt ?? receipt.scannedAt;
      final key = DateFormat('yyyy-MM-dd').format(date);
      groups.putIfAbsent(key, () => []).add(receipt);
    }
    final canRefresh = state.receipts.any((row) => row.canRetry);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          if (canRefresh)
            PopupMenuButton<String>(
              enabled: !_busy,
              tooltip: l10n.refreshPending,
              onSelected: (value) {
                if (value == 'reload_items') _refreshPending();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'reload_items',
                  child: Text(l10n.refreshPending),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: state.receipts.isEmpty
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
                        ...entry.value.map((receipt) => ReceiptCard(receipt: receipt, state: state)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

