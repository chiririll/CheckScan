import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/format/format.dart';
import '../../core/models/receipt_record.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../merchant/merchant_page.dart';
import '../widgets/dialogs.dart';
import '../widgets/navigation.dart';
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
  ReceiptRecord? get _record => widget.state.byId(widget.receiptId);

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmAction(
      context,
      title: l10n.deleteReceiptTitle,
      body: l10n.deleteReceiptBody,
      confirm: l10n.deleteReceipt,
    );
    if (!confirmed || !mounted) return;
    await widget.state.deleteReceipt(widget.receiptId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _refresh() async {
    final current = _record;
    if (current == null) return;
    try {
      await widget.state.refreshReceipt(current);
    } catch (_) {
      if (mounted) showSnack(context, AppLocalizations.of(context).parseErrorBody);
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
        final name = record.displayMerchant(l10n.receiptTitle);
        final merchantId = record.merchantId;
        const nameStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 18);
        final when = record.at;

        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: _ReceiptCrumbs(l10n: l10n),
            actions: [
              PopupMenuButton<String>(
                tooltip: l10n.receiptActions,
                onSelected: (value) {
                  if (value == 'delete') _confirmDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.deleteReceipt, style: AppText.danger),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: merchantId == null
                            ? null
                            : () => pushPage<void>(context, MerchantPage(state: widget.state, merchantId: merchantId)),
                        child: Text(name, style: nameStyle),
                      ),
                    ),
                    if (record.providerLabel.isNotEmpty) _Chip(record.providerLabel),
                  ],
                ),
                const SizedBox(height: 4),
                Text(formatDateTime(when), style: AppText.muted),
                const SizedBox(height: 8),
                Text(
                  formatMoney(record.grandTotal, record.currency),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                if (widget.state.isFetching(record.id)) ...[
                  const SizedBox(height: 12),
                  _FetchingRow(label: l10n.progressLoading),
                ] else if (record.status == ReceiptStatus.error) ...[
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
                if (receipt.items.isNotEmpty) ReceiptItemList(record: record),
                const SizedBox(height: 8),
                const Divider(),
                ReceiptMetadataTile(record: record),
              ],
            ),
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
    const muted = TextStyle(color: AppColors.muted, fontSize: 16, fontWeight: FontWeight.w400);
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

/// Shown while the provider is still being asked for items.
class _FetchingRow extends StatelessWidget {
  const _FetchingRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('receipt-fetching'),
      children: [
        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppText.muted)),
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
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
    );
  }
}
