import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../labels/category_label.dart';
import '../widgets/bottom_action.dart';
import '../widgets/card_tile.dart';
import '../widgets/dialogs.dart';
import '../widgets/empty_hint.dart';
import '../widgets/navigation.dart';
import 'catalog_nav.dart';
import 'catalog_trail.dart';
import 'product_page.dart';

/// A top shelf lists its children; a leaf (or a childless top) lists its products.
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.state, required this.categoryId});

  final AppState state;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final catalog = state.catalog;
        final category = catalog.categoryById(categoryId);
        if (category == null) {
          return Scaffold(appBar: AppBar(title: Text(l10n.catalogCategories)));
        }
        final parent = category.parentId == null ? null : catalog.categoryById(category.parentId!);
        final children = catalog.childrenOf(category.id);
        final products = [for (final product in catalog.products) if (product.categoryId == category.id) product];
        return Scaffold(
          appBar: CatalogAppBar(
            title: categoryTitle(category, l10n),
            ancestors: [
              CatalogCrumb(label: l10n.catalogTitle, onTap: () => openCatalog(context, state)),
              CatalogCrumb(
                label: l10n.catalogCategories,
                onTap: () => openCatalog(context, state, tab: CatalogTab.categories),
              ),
              if (category.parentId != null)
                CatalogCrumb(label: categoryTitle(parent ?? category, l10n), onTap: () => Navigator.pop(context)),
            ],
          ),
          body: children.isNotEmpty
              ? CardList(
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index];
                    final count = catalog.products.where((product) => product.categoryId == child.id).length;
                    return CardTile(
                      title: categoryTitle(child, l10n),
                      subtitle: l10n.itemsCount(count),
                      onTap: () => pushPage<void>(context, CategoryPage(state: state, categoryId: child.id)),
                    );
                  },
                )
              : products.isEmpty
                  ? EmptyHint(title: l10n.catalogEmptyProducts, body: l10n.catalogEmptyProductsBody)
                  : CardList(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return CardTile(
                          title: product.name,
                          onTap: () => pushPage<void>(
                            context,
                            ProductPage(state: state, productId: product.id, fromCategoryId: category.id),
                          ),
                        );
                      },
                    ),
          bottomNavigationBar: category.isTop
              ? BottomAction(
                  label: l10n.addChildCategory,
                  onPressed: () async {
                    final name = await promptText(context, title: l10n.addChildCategory, confirm: l10n.save);
                    if (name != null) await catalog.createCategory(name, parentId: category.id);
                  },
                )
              : null,
        );
      },
    );
  }
}
