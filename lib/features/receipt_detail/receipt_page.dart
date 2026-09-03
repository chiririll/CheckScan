import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/models/receipt_record.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import 'receipt_items.dart';
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
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
            child: Text(l10n.deleteReceipt),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
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
      await widget.state.refreshReceipt(current);
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
            title: _ReceiptCrumbs(l10n: l10n),
            actions: [
              PopupMenuButton<String>(
                enabled: !_busy,
                tooltip: l10n.receiptActions,
                onSelected: (value) {
                  if (value == 'refresh') _refresh();
                  if (value == 'delete') _confirmDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'refresh', child: Text(l10n.refreshReceipt)),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.deleteReceipt, style: const TextStyle(color: Color(0xFFC62828))),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (_busy) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: ListView(
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
                    if (record.status == ReceiptStatus.error) ...[
                      const SizedBox(height: 12),
                      Text(l10n.parseErrorBody, style: TextStyle(color: Colors.grey.shade700)),
                    ] else if (receipt.items.isEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        record.itemsUnavailable || record.status == ReceiptStatus.ok
                            ? l10n.noItemsBanner
                            : l10n.missingItemsHint,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                    if (receipt.items.isNotEmpty) ReceiptItemList(state: widget.state, record: record),
                    const SizedBox(height: 8),
                    const Divider(),
                    ReceiptMetadataTile(record: record),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReceiptCrumbs extends StatelessWidget {
  const _ReceiptCrumbs({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w400);
    return Row(
      children: [
        Flexible(
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Text(l10n.historyTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500),
        ),
        Flexible(
          child: Text(l10n.receiptTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
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
