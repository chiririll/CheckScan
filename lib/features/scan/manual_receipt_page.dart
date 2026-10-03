import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/format/format.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/navigation.dart';
import 'manual/manual_line.dart';
import 'manual/pick_sheets.dart';

/// Receipt typed by hand from catalog products. Pops with the saved receipt id.
class ManualReceiptPage extends StatefulWidget {
  const ManualReceiptPage({super.key, required this.state});

  final AppState state;

  @override
  State<ManualReceiptPage> createState() => _ManualReceiptPageState();
}

class _ManualReceiptPageState extends State<ManualReceiptPage> {
  final _merchant = TextEditingController();
  DateTime _issuedAt = DateTime.now();
  final _lines = <ManualLineDraft>[];
  bool _busy = false;

  @override
  void dispose() {
    _merchant.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final next = await showDatePicker(
      context: context,
      initialDate: _issuedAt,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (next == null) return;
    setState(() => _issuedAt = DateTime(next.year, next.month, next.day, _issuedAt.hour, _issuedAt.minute));
  }

  Future<void> _pickMerchant() async {
    final picked = await pickMerchantName(context, widget.state.merchants.all);
    if (picked != null) _merchant.text = picked;
  }

  Future<void> _addLine() async {
    final l10n = AppLocalizations.of(context);
    final taken = {for (final line in _lines) line.product.id};
    final products = [for (final product in widget.state.catalog.products) if (!taken.contains(product.id)) product];
    if (products.isEmpty) {
      showSnack(context, l10n.manualNoProducts);
      return;
    }
    final picked = await pickProduct(context, products, hint: l10n.manualProductHint);
    if (picked == null) return;
    setState(() => _lines.add(ManualLineDraft(product: picked)));
  }

  Future<void> _save() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final merchant = _merchant.text.trim();
    if (merchant.isEmpty) {
      showSnack(context, l10n.manualNeedMerchant);
      return;
    }
    final positions = widget.state.catalog.positions;
    final lines = [for (final line in _lines) if (line.isValid) line.toManual(positions)];
    if (lines.isEmpty) {
      showSnack(context, l10n.manualNeedLines);
      return;
    }
    setState(() => _busy = true);
    try {
      final saved = await widget.state.saveManualReceipt(merchantName: merchant, issuedAt: _issuedAt, lines: lines);
      if (mounted) Navigator.of(context).pop(saved.id);
    } catch (_) {
      if (!mounted) return;
      showSnack(context, l10n.parseErrorBody);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = _lines.fold<double>(0, (sum, line) => sum + line.total);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manualReceiptTitle),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.manualSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            controller: _merchant,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.manualMerchant,
              hintText: l10n.manualMerchantHint,
              border: const OutlineInputBorder(),
              suffixIcon: widget.state.merchants.all.isEmpty
                  ? null
                  : IconButton(icon: const Icon(Icons.storefront_outlined), onPressed: _pickMerchant),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.manualDate),
            subtitle: Text(formatDayHeader(_issuedAt)),
            trailing: const Icon(Icons.calendar_today_outlined, size: 18),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          if (_lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(l10n.manualEmptyLines, style: AppText.muted),
            ),
          for (var i = 0; i < _lines.length; i++)
            ManualLineTile(
              key: ValueKey(_lines[i].product.id),
              line: _lines[i],
              onRemove: () => setState(() => _lines.removeAt(i).dispose()),
              onChanged: () => setState(() {}),
            ),
          TextButton.icon(onPressed: _addLine, icon: const Icon(Icons.add), label: Text(l10n.manualAddLine)),
          if (_lines.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Text(formatMoney(total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ),
        ],
      ),
    );
  }
}
