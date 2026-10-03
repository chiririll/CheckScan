import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/catalog/model/catalog_category.dart';
import '../../../core/state/app_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../labels/category_label.dart';
import '../../widgets/bottom_action.dart';
import '../../widgets/card_tile.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/navigation.dart';
import '../category_page.dart';

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = state.catalog;
    final tops = catalog.topCategories;
    return Column(
      children: [
        Expanded(
          child: CardList(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: tops.length,
            itemBuilder: (context, index) {
              final category = tops[index];
              final ids = {category.id, for (final child in catalog.childrenOf(category.id)) child.id};
              final count = catalog.products.where((product) => ids.contains(product.categoryId)).length;
              return CardTile(
                title: categoryTitle(category, l10n),
                subtitle: l10n.itemsCount(count),
                onTap: () => pushPage<void>(context, CategoryPage(state: state, categoryId: category.id)),
                trailing: _CategoryMenu(state: state, category: category),
              );
            },
          ),
        ),
        BottomAction(
          label: l10n.addCategory,
          onPressed: () async {
            final name = await promptText(context, title: l10n.addCategory, confirm: l10n.save);
            if (name != null) await catalog.createCategory(name);
          },
        ),
      ],
    );
  }
}

enum _CategoryAction { rename, delete }

class _CategoryMenu extends StatelessWidget {
  const _CategoryMenu({required this.state, required this.category});

  final AppState state;
  final CatalogCategory category;

  Future<void> _onSelected(BuildContext context, _CategoryAction action) async {
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case _CategoryAction.rename:
        final current = categoryTitle(category, l10n);
        final name = await promptText(context, title: l10n.categoryName, initial: current, confirm: l10n.save);
        if (name != null && name != current) await state.catalog.renameCategory(category.id, name);
      case _CategoryAction.delete:
        final ok = await confirmAction(
          context,
          title: l10n.deleteCategoryTitle,
          body: l10n.deleteCategoryBody,
          confirm: l10n.deleteReceipt,
        );
        if (ok) await state.catalog.deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_CategoryAction>(
      onSelected: (action) => _onSelected(context, action),
      itemBuilder: (context) => [
        PopupMenuItem(value: _CategoryAction.rename, child: Text(l10n.rename)),
        PopupMenuItem(value: _CategoryAction.delete, child: Text(l10n.deleteReceipt, style: AppText.danger)),
      ],
    );
  }
}
