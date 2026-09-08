import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_state.dart';
import '../../core/catalog/catalog_product.dart';
import '../../core/format.dart';
import '../../core/manual/manual_receipt.dart';
import '../../l10n/app_localizations.dart';

class ManualReceiptPage extends StatefulWidget {
  const ManualReceiptPage({super.key, required this.state});

  final AppState state;

  @override
  State<ManualReceiptPage> createState() => _ManualReceiptPageState();
}

class _ManualReceiptPageState extends State<ManualReceiptPage> {
  final _merchant = TextEditingController();
  DateTime _issuedAt = DateTime.now();
  final _lines = <_DraftLine>[];
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

  Future<void> _addLine() async {
    final taken = {for (final line in _lines) line.product.id};
    final products = [for (final product in widget.state.catalog.products) if (!taken.contains(product.id)) product];
    final l10n = AppLocalizations.of(context);
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.manualNoProducts)));
      return;
    }
    final picked = await showModalBottomSheet<CatalogProduct>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProductPicker(products: products, hint: l10n.manualProductHint),
    );
    if (picked == null) return;
    setState(() => _lines.add(_DraftLine(product: picked)));
  }

  Future<void> _save() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final merchant = _merchant.text.trim();
    if (merchant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.manualNeedMerchant)));
      return;
    }
    final lines = [for (final line in _lines) if (line.isValid) line.toManual(widget.state)];
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.manualNeedLines)));
      return;
    }
    setState(() => _busy = true);
    try {
      final saved = await widget.state.saveManualReceipt(
        merchantName: merchant,
        issuedAt: _issuedAt,
        lines: lines,
      );
      if (!mounted) return;
      Navigator.of(context).pop(saved.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.parseErrorBody)));
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
              suffixIcon: widget.state.merchantList.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.storefront_outlined),
                      onPressed: () async {
                        final picked = await showModalBottomSheet<String>(
                          context: context,
                          builder: (context) => SafeArea(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                for (final merchant in widget.state.merchantList)
                                  ListTile(
                                    title: Text(merchant.name),
                                    onTap: () => Navigator.pop(context, merchant.name),
                                  ),
                              ],
                            ),
                          ),
                        );
                        if (picked != null) _merchant.text = picked;
                      },
                    ),
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
              child: Text(l10n.manualEmptyLines, style: TextStyle(color: Colors.grey.shade600)),
            ),
          for (var i = 0; i < _lines.length; i++)
            _LineTile(
              key: ValueKey(_lines[i].product.id),
              line: _lines[i],
              onRemove: () => setState(() {
                _lines.removeAt(i).dispose();
              }),
              onChanged: () => setState(() {}),
            ),
          TextButton.icon(
            onPressed: _addLine,
            icon: const Icon(Icons.add),
            label: Text(l10n.manualAddLine),
          ),
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

class _DraftLine {
  _DraftLine({required this.product})
      : qty = TextEditingController(text: '1'),
        price = TextEditingController();

  final CatalogProduct product;
  final TextEditingController qty;
  final TextEditingController price;

  double get quantity => double.tryParse(qty.text.replaceAll(',', '.')) ?? 0;
  double get unitPrice => double.tryParse(price.text.replaceAll(',', '.')) ?? 0;
  double get total => quantity * unitPrice;
  bool get isValid => quantity > 0 && unitPrice >= 0 && price.text.trim().isNotEmpty;

  ManualLine toManual(AppState state) {
    return ManualLine(
      productId: product.id,
      description: lineDescriptionFor(product: product, positions: state.catalog.positions),
      quantity: quantity,
      unitPrice: unitPrice,
    );
  }

  void dispose() {
    qty.dispose();
    price.dispose();
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({super.key, required this.line, required this.onRemove, required this.onChanged});

  final _DraftLine line;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(line.product.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              IconButton(onPressed: onRemove, icon: const Icon(Icons.close, size: 18)),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: line.qty,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: InputDecoration(labelText: l10n.manualQuantity),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: line.price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: InputDecoration(labelText: l10n.manualPrice),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductPicker extends StatefulWidget {
  const _ProductPicker({required this.products, required this.hint});

  final List<CatalogProduct> products;
  final String hint;

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final needle = _query.trim().toLowerCase();
    final shown = [
      for (final product in widget.products)
        if (needle.isEmpty || product.name.toLowerCase().contains(needle)) product,
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(hintText: widget.hint, border: const OutlineInputBorder()),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final product in shown)
                    ListTile(
                      title: Text(product.name),
                      onTap: () => Navigator.pop(context, product),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
