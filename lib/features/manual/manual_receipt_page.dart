import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../core/format/format.dart';
import '../../core/manual/manual_receipt.dart';
import '../../core/models/receipt_record.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../receipt_detail/receipt_page.dart';
import '../widgets/navigation.dart';
import 'manual_item_row.dart';

/// Form for a receipt without a QR. With [existing] it edits that receipt.
class ManualReceiptPage extends StatefulWidget {
  const ManualReceiptPage({super.key, required this.state, this.existing});

  final AppState state;
  final ReceiptRecord? existing;

  @override
  State<ManualReceiptPage> createState() => _ManualReceiptPageState();
}

class _ManualReceiptPageState extends State<ManualReceiptPage> {
  late final ManualReceiptDraft _draft = _initialDraft();
  late final _total = TextEditingController(text: _draft.totalText);
  bool _saving = false;

  ManualReceiptDraft _initialDraft() {
    final existing = widget.existing;
    if (existing != null) return ManualReceiptDraft.fromReceipt(existing.receipt);
    return ManualReceiptDraft(currency: widget.state.defaultCurrency);
  }

  /// Offered currencies; an edited receipt's own one stays selectable even if it fell out of the list.
  List<String> get _currencies {
    final offered = widget.state.manualCurrencies;
    return offered.contains(_draft.currency) ? offered : [_draft.currency, ...offered];
  }

  @override
  void dispose() {
    _total.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final current = _draft.issuedAt;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(current));
    if (time == null) return;
    setState(() => _draft.issuedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final existing = widget.existing;
    final built = buildManualReceipt(_draft, id: existing?.receipt.id ?? const Uuid().v4());
    final receipt = built.receipt;
    if (receipt == null) {
      showSnack(
        context,
        built.error == ManualReceiptError.invalidItem ? l10n.manualInvalidItem : l10n.manualInvalidTotal,
      );
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final record = await widget.state.saveManual(receipt, label: l10n.manualProviderLabel, existing: existing);
    if (!mounted) return;
    if (existing != null) {
      navigator.pop();
    } else {
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => ReceiptPage(state: widget.state, receiptId: record.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasItems = _draft.filledItems.isNotEmpty;
    final total = _draft.total;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? l10n.manualTitleNew : l10n.manualTitleEdit),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _draft.merchantName),
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              if (query.isEmpty) return const Iterable<String>.empty();
              return widget.state.merchants.all
                  .map((merchant) => merchant.name)
                  .where((name) => name.toLowerCase().contains(query));
            },
            onSelected: (name) => _draft.merchantName = name,
            fieldViewBuilder: (context, controller, focus, _) => TextField(
              controller: controller,
              focusNode: focus,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.manualMerchant),
              onChanged: (text) => _draft.merchantName = text,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: l10n.manualDate),
                    child: Text(formatDateTime(_draft.issuedAt)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _draft.currency,
                items: [
                  for (final code in _currencies)
                    DropdownMenuItem(value: code, child: Text(formatCurrencyLabel(code))),
                ],
                onChanged: (code) => setState(() => _draft.currency = code ?? _draft.currency),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.manualItems, style: AppText.title),
          const SizedBox(height: 8),
          for (final item in _draft.items)
            ManualItemRow(
              key: ObjectKey(item),
              item: item,
              currency: _draft.currency,
              onChanged: () => setState(() {}),
              onRemove: () => setState(() => _draft.items.remove(item)),
            ),
          TextButton.icon(
            onPressed: () => setState(() => _draft.items.add(ManualItemDraft())),
            icon: const Icon(Icons.add),
            label: Text(l10n.manualAddItem),
          ),
          const Divider(height: 32),
          if (hasItems)
            Row(
              children: [
                Expanded(child: Text(l10n.manualTotal, style: AppText.title)),
                Text(
                  total == null ? '—' : formatMoney(total, scale: manualScale, currency: _draft.currency),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            )
          else
            TextField(
              controller: _total,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.manualTotal),
              onChanged: (text) => setState(() => _draft.totalText = text),
            ),
        ],
      ),
    );
  }
}
