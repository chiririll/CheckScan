import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/catalog/model/catalog_position.dart';
import '../../../core/catalog/model/catalog_product.dart';
import '../../../core/state/app_state.dart';
import '../../../l10n/app_localizations.dart';
import '../assign_sheet.dart';
import 'position_amount.dart';
import 'tag_wrap.dart';

/// A product's position: pack size, tags, reassignment and alias split.
class PositionCard extends StatelessWidget {
  const PositionCard({super.key, required this.state, required this.position, required this.product});

  final AppState state;
  final CatalogPosition position;
  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = state.catalog;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: AppShapes.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(position.displayName),
            PositionAmountTile(catalog: catalog, position: position, product: product),
            Text(l10n.itemTags, style: AppText.mutedSmall),
            const SizedBox(height: 4),
            TagWrap(
              tags: position.tags,
              onAdd: (name) => catalog.addItemTag(position.id, name),
              onRemove: (tagId) => catalog.removeItemTag(position.id, tagId),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => showAssignSheet(context: context, state: state, position: position),
                  child: Text(l10n.assignToProduct),
                ),
                TextButton(
                  onPressed: () => catalog.assignPosition(position.id, null),
                  child: Text(l10n.detachPosition),
                ),
              ],
            ),
            if (position.aliases.length > 1)
              for (final alias in position.aliases)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(alias, style: const TextStyle(fontSize: 13)),
                  trailing: TextButton(onPressed: () => catalog.unalias(alias), child: Text(l10n.splitAlias)),
                ),
          ],
        ),
      ),
    );
  }
}
