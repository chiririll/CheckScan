import 'package:flutter/material.dart';

import '../../core/format/format.dart';
import '../../core/manual/manual_receipt.dart';
import '../../l10n/app_localizations.dart';

/// One editable receipt line. Owns its controllers; edits go straight into [item].
class ManualItemRow extends StatefulWidget {
  const ManualItemRow({
    super.key,
    required this.item,
    required this.currency,
    required this.onChanged,
    required this.onRemove,
  });

  final ManualItemDraft item;
  final String currency;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<ManualItemRow> createState() => _ManualItemRowState();
}

class _ManualItemRowState extends State<ManualItemRow> {
  late final _name = TextEditingController(text: widget.item.name);
  late final _qty = TextEditingController(text: widget.item.quantity);
  late final _price = TextEditingController(text: widget.item.price);

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  void _changed() {
    widget.item
      ..name = _name.text
      ..quantity = _qty.text
      ..price = _price.text;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const number = TextInputType.numberWithOptions(decimal: true);
    final sum = widget.item.sum;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.manualItemName),
                  onChanged: (_) => _changed(),
                ),
              ),
              IconButton(
                tooltip: l10n.manualRemoveItem,
                icon: const Icon(Icons.close),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qty,
                  keyboardType: number,
                  decoration: InputDecoration(labelText: l10n.manualItemQty, hintText: '1'),
                  onChanged: (_) => _changed(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: number,
                  decoration: InputDecoration(labelText: l10n.manualItemPrice),
                  onChanged: (_) => _changed(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: Text(
                  sum == null ? '' : formatMoney(sum, scale: manualScale, currency: widget.currency),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
