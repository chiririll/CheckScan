import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/empty_hint.dart';
import '../widgets/navigation.dart';
import 'receipt_day_list.dart';

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
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await state.refreshPending();
      if (mounted) showSnack(context, l10n.refreshPendingDone);
    } catch (_) {
      if (mounted) showSnack(context, l10n.parseErrorBody);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canRefresh = state.receipts.any((row) => row.canRetry);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          if (canRefresh)
            PopupMenuButton<String>(
              enabled: !_busy,
              tooltip: l10n.refreshPending,
              onSelected: (_) => _refreshPending(),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'reload_items', child: Text(l10n.refreshPending)),
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
                : ReceiptDayList(state: state, receipts: state.receipts),
          ),
        ],
      ),
    );
  }
}
