import 'package:eq_models/eq_models.dart';
import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/catalog/catalog_resolver.dart';
import '../../core/catalog/category_label.dart';
import '../../core/format.dart';
import '../../core/models/receipt_record.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/assign_sheet.dart';
import '../catalog/unit_labels.dart';

class ReceiptItemList extends StatelessWidget {
  const ReceiptItemList({super.key, required this.state, required this.record});

  final AppState state;
  final ReceiptRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = record.receipt.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final groups = groupReceiptItems(items, state.catalog.resolver, l10n.uncategorized);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(),
        Text(l10n.itemsSection, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        for (final group in groups) ...[
          if (group.title != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Text(categoryLabel(group.title!, l10n), style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
            ),
          ],
          for (final item in group.items)
            _ItemRow(state: state, record: record, item: item),
        ],
      ],
    );
  }
}

class ReceiptItemGroup {
  const ReceiptItemGroup({this.title, required this.items});
  final String? title;
  final List<EqItem> items;
}

List<ReceiptItemGroup> groupReceiptItems(List<EqItem> items, CatalogResolver resolver, String uncategorized) {
  final mapped = <String, List<EqItem>>{};
  final order = <String>[];
  var hasCategory = false;
  for (final item in items) {
    final name = resolver.categoryName(item.description);
    if (name != null) hasCategory = true;
    final key = name ?? '';
    if (!mapped.containsKey(key)) {
      order.add(key);
      mapped[key] = [];
    }
    mapped[key]!.add(item);
  }
  if (!hasCategory) return [ReceiptItemGroup(items: items)];
  return [
    for (final key in order)
      if (key.isNotEmpty) ReceiptItemGroup(title: key, items: mapped[key]!),
    if (mapped[''] != null) ReceiptItemGroup(title: uncategorized, items: mapped['']!),
  ];
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.state, required this.record, required this.item});

  final AppState state;
  final ReceiptRecord record;
  final EqItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hit = state.catalog.resolver.resolve(item.description);
    final unit = hit == null ? '' : formatCatalogUnit(hit.position.unit, hit.position.unitSize, l10n);
    final product = hit?.product?.name;
    final subtitle = [
      ?product,
      if (unit.isNotEmpty) unit,
    ].join(' · ');
    return InkWell(
      onTap: hit == null
          ? null
          : () => showAssignSheet(context: context, state: state, position: hit.position),
      child: Padding(
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
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Text(formatMoney(item.totalPrice, record.currency), style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
