import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/models/receipt_record.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import 'receipt_metadata.dart';

class ReceiptPage extends StatefulWidget {
  const ReceiptPage({super.key, required this.state, required this.receiptId});

  final AppState state;
  final String receiptId;

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  bool _busy = false;

  ReceiptRecord? get _record => widget.state.byId(widget.receiptId);

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteReceiptTitle),
        content: Text(l10n.deleteReceiptBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.deleteReceipt)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.state.deleteReceipt(widget.receiptId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _refresh() async {
    final current = _record;
    if (current == null) return;
    setState(() => _busy = true);
    try {
      await widget.state.session.refresh(current);
      await widget.state.reload();
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.parseErrorBody)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final record = _record;
        if (record == null) {
          return Scaffold(appBar: AppBar(leading: const BackButton(), title: Text(l10n.receiptTitle)));
        }
        final receipt = record.receipt;
        final name = record.merchantName?.isNotEmpty == true ? record.merchantName! : l10n.receiptTitle;
        final when = record.issuedAt ?? record.scannedAt;

        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: Text(l10n.receiptTitle),
            actions: [
              IconButton(
                onPressed: _busy ? null : _confirmDelete,
                tooltip: l10n.deleteReceipt,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
          Row(
            children: [
              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18))),
              if (record.providerLabel.isNotEmpty) _Chip(record.providerLabel),
            ],
          ),
          const SizedBox(height: 4),
          Text(formatDateTime(when), style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(
            formatMoney(record.grandTotal, record.currency),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          if (record.canRetry) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFE8EEED), borderRadius: BorderRadius.circular(8)),
              child: Text(
                record.status == ReceiptStatus.error ? l10n.parseErrorBody : l10n.noItemsBanner,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _refresh,
              child: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(record.status == ReceiptStatus.error ? l10n.retry : l10n.retryItems),
            ),
          ],
          if (receipt.items.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            Text(l10n.itemsSection, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...receipt.items.map((item) {
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
                            l10n.qtyPrice(formatQty(item.quantity), formatMoney(item.unitPrice, record.currency)),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(formatMoney(item.totalPrice, record.currency), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 8),
          const Divider(),
          ReceiptMetadataTile(record: record),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE4EEEC),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
    );
  }
}
