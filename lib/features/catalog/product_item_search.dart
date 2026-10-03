import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/catalog/model/catalog_position.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import 'catalog_search_field.dart';

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
        CatalogSearchField(
          controller: _query,
          hintText: l10n.itemSearchHint,
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
          Text(l10n.similarItems, style: AppText.title),
          const SizedBox(height: 8),
          for (final item in similar.take(8))
            _AttachRow(
              item: item,
              elsewhere: false,
              onAttach: () => catalog.assignPosition(item.id, widget.productId),
              onDismiss: () => catalog.dismissProductSuggestion(productId: widget.productId, itemId: item.id),
            ),
        ],
      ],
    );
  }
}

class _AttachRow extends StatelessWidget {
  const _AttachRow({required this.item, required this.elsewhere, required this.onAttach, this.onDismiss});

  final CatalogPosition item;
  final bool elsewhere;
  final VoidCallback onAttach;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(item.displayName),
      subtitle: elsewhere ? Text(l10n.itemAssignedElsewhere, style: const TextStyle(color: AppColors.muted, fontSize: 12)) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(onPressed: onAttach, child: Text(l10n.attachItem, style: const TextStyle(color: AppColors.primary))),
          if (onDismiss != null)
            IconButton(
              tooltip: l10n.dismissSuggestion,
              visualDensity: VisualDensity.compact,
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
            ),
        ],
      ),
    );
  }
}
