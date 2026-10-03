import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../core/catalog/model/catalog_position.dart';
import '../../../core/catalog/model/catalog_product.dart';
import '../../../core/format/format.dart';
import '../../../core/manual/manual_receipt.dart';
import '../../../l10n/app_localizations.dart';

/// Editable line of a manual receipt: a catalog product with typed quantity and price.
class ManualLineDraft {
  ManualLineDraft({required this.product})
      : qty = TextEditingController(text: '1'),
        price = TextEditingController();

  final CatalogProduct product;
  final TextEditingController qty;
  final TextEditingController price;

  double get quantity => parseDecimal(qty.text) ?? 0;
  double get unitPrice => parseDecimal(price.text) ?? 0;
  double get total => quantity * unitPrice;
  bool get isValid => quantity > 0 && unitPrice >= 0 && price.text.trim().isNotEmpty;

  ManualLine toManual(Iterable<CatalogPosition> positions) {
    return ManualLine(
      productId: product.id,
      description: lineDescriptionFor(product: product, positions: positions),
      quantity: quantity,
      unitPrice: unitPrice,
    );
  }

  void dispose() {
    qty.dispose();
    price.dispose();
  }
}

class ManualLineTile extends StatelessWidget {
  const ManualLineTile({super.key, required this.line, required this.onRemove, required this.onChanged});

  final ManualLineDraft line;
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
        borderRadius: AppShapes.radius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(line.product.name, style: AppText.title)),
              IconButton(onPressed: onRemove, icon: const Icon(Icons.close, size: 18)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _DecimalField(controller: line.qty, label: l10n.manualQuantity, onChanged: onChanged)),
              const SizedBox(width: 12),
              Expanded(child: _DecimalField(controller: line.price, label: l10n.manualPrice, onChanged: onChanged)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecimalField extends StatelessWidget {
  const _DecimalField({required this.controller, required this.label, required this.onChanged});

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => onChanged(),
    );
  }
}
