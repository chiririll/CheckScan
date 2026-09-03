import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/catalog/catalog_position.dart';
import '../../core/catalog/category_label.dart';
import '../../core/catalog/item_unit.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import 'assign_sheet.dart';
import 'catalog_dialogs.dart';
import 'unit_labels.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key, required this.state, required this.productId});

  final AppState state;
  final String productId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final product = state.catalog.productById(productId);
        if (product == null) {
          return Scaffold(appBar: AppBar(title: Text(l10n.catalogProducts)));
        }
        final positions = [for (final position in state.catalog.positions) if (position.productId == product.id) position];
        return Scaffold(
          appBar: AppBar(
            title: Text(product.name),
            actions: [
              IconButton(
                tooltip: l10n.deleteProduct,
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: l10n.deleteProductTitle,
                    body: l10n.deleteProductBody,
                    confirm: l10n.deleteProduct,
                  );
                  if (!ok || !context.mounted) return;
                  await state.catalog.deleteProduct(product.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.productName),
                subtitle: Text(product.name),
                onTap: () async {
                  final name = await promptText(context, title: l10n.productName, initial: product.name, confirm: l10n.save);
                  if (name != null) await state.catalog.updateProduct(product.id, name: name);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.productCategory),
                subtitle: Text(_categorySubtitle(product.categoryId, l10n)),
                onTap: () => _pickCategory(context, product.id, product.categoryId),
              ),
              const SizedBox(height: 8),
              Text(l10n.productTags, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in product.tags)
                    InputChip(
                      label: Text(tag.name),
                      onDeleted: () => state.catalog.removeTag(product.id, tag.id),
                    ),
                  ActionChip(
                    label: Text(l10n.addTag),
                    onPressed: () async {
                      final name = await promptText(context, title: l10n.addTag, confirm: l10n.save);
                      if (name != null) await state.catalog.addTag(product.id, name);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.itemsSection, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              for (final position in positions) _PositionTile(state: state, position: position),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickCategory(BuildContext context, String productId, String? currentId) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(l10n.noCategory),
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final category in state.catalog.categories)
              ListTile(
                title: Text(categoryTitle(category, l10n)),
                selected: category.id == currentId,
                onTap: () => Navigator.pop(context, category.id),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    if (selected.isEmpty) {
      await state.catalog.updateProduct(productId, clearCategory: true);
    } else {
      await state.catalog.updateProduct(productId, categoryId: selected);
    }
  }

  String _categorySubtitle(String? categoryId, AppLocalizations l10n) {
    if (categoryId == null) return l10n.noCategory;
    final category = state.catalog.categoryById(categoryId);
    if (category == null) return l10n.noCategory;
    return categoryTitle(category, l10n);
  }
}

class _PositionTile extends StatelessWidget {
  const _PositionTile({required this.state, required this.position});

  final AppState state;
  final CatalogPosition position;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = formatCatalogUnit(position.unit, position.unitSize, l10n);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE4E4E4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(position.displayName)),
                DropdownButton<ItemUnit?>(
                  value: position.unit,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.unitNone)),
                    for (final item in ItemUnit.values) DropdownMenuItem(value: item, child: Text(unitLabel(item, l10n))),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      state.catalog.updatePosition(position.id, clearUnit: true);
                    } else {
                      state.catalog.updatePosition(position.id, unit: value, unitSize: position.unitSize);
                    }
                  },
                ),
              ],
            ),
            if (unit.isNotEmpty) Text(unit, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => showAssignSheet(context: context, state: state, position: position),
                  child: Text(l10n.assignToProduct),
                ),
                TextButton(
                  onPressed: () => state.catalog.assignPosition(position.id, null),
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
                  trailing: TextButton(
                    onPressed: () => state.catalog.unalias(alias),
                    child: Text(l10n.splitAlias),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
