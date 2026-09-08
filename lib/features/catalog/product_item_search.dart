import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/catalog/catalog_position.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';

class ProductItemSearch extends StatefulWidget {
  const ProductItemSearch({super.key, required this.state, required this.productId});

  final AppState state;
  final String productId;

  @override
  State<ProductItemSearch> createState() => _ProductItemSearchState();
}

class _ProductItemSearchState extends State<ProductItemSearch> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = widget.state.catalog;
    final hits = catalog.searchAttachableItems(widget.productId, _query.text);
    final similar = _query.text.trim().isEmpty ? catalog.similarCandidatesFor(widget.productId) : const <CatalogPosition>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _query,
          decoration: InputDecoration(
            hintText: l10n.itemSearchHint,
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (hits.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final item in hits.take(8))
            _AttachRow(
              item: item,
              elsewhere: item.productId != null,
              onAttach: () => catalog.assignPosition(item.id, widget.productId),
            ),
        ],
        if (similar.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.similarItems, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final item in similar.take(8))
            _AttachRow(
              item: item,
              elsewhere: false,
              onAttach: () => catalog.assignPosition(item.id, widget.productId),
            ),
        ],
      ],
    );
  }
}

class _AttachRow extends StatelessWidget {
  const _AttachRow({required this.item, required this.elsewhere, required this.onAttach});

  final CatalogPosition item;
  final bool elsewhere;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(item.displayName),
      subtitle: elsewhere ? Text(l10n.itemAssignedElsewhere, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)) : null,
      trailing: TextButton(onPressed: onAttach, child: Text(l10n.attachItem, style: const TextStyle(color: AppColors.primary))),
    );
  }
}
