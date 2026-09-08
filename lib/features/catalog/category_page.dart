import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/catalog/catalog_category.dart';
import '../../core/catalog/category_label.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/empty_hint.dart';
import 'catalog_dialogs.dart';
import 'catalog_nav.dart';
import 'catalog_trail.dart';
import 'product_page.dart';

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
        final category = state.catalog.categoryById(categoryId);
        if (category == null) {
          return Scaffold(appBar: AppBar(title: Text(l10n.catalogCategories)));
        }
        final children = state.catalog.childrenOf(category.id);
        final products = [for (final product in state.catalog.products) if (product.categoryId == category.id) product];
        final crumbs = [
          CatalogCrumb(label: l10n.catalogTitle, onTap: () => openCatalog(context, state)),
          CatalogCrumb(label: l10n.catalogCategories, onTap: () => openCatalog(context, state, tab: 2)),
          if (category.parentId != null)
            CatalogCrumb(
              label: categoryTitle(state.catalog.categoryById(category.parentId!) ?? category, l10n),
              onTap: () => Navigator.pop(context),
            ),
          CatalogCrumb(label: categoryTitle(category, l10n)),
        ];
        return Scaffold(
          appBar: AppBar(title: CatalogTrail(crumbs: crumbs)),
          body: children.isNotEmpty
              ? _ChildList(state: state, children: children)
              : products.isEmpty
                  ? EmptyHint(title: l10n.catalogEmptyProducts, body: l10n.catalogEmptyProductsBody)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: products.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFE4E4E4)),
                          ),
                          title: Text(product.name),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ProductPage(state: state, productId: product.id, fromCategoryId: category.id),
                            ),
                          ),
                        );
                      },
                    ),
          bottomNavigationBar: category.isTop
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: FilledButton(
                      onPressed: () async {
                        final name = await promptText(context, title: l10n.addChildCategory, confirm: l10n.save);
                        if (name != null) await state.catalog.createCategory(name, parentId: category.id);
                      },
                      child: Text(l10n.addChildCategory),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _ChildList extends StatelessWidget {
  const _ChildList({required this.state, required this.children});

  final AppState state;
  final List<CatalogCategory> children;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: children.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final child = children[index];
        final count = state.catalog.products.where((product) => product.categoryId == child.id).length;
        return ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE4E4E4)),
          ),
          title: Text(categoryTitle(child, l10n)),
          subtitle: Text(l10n.itemsCount(count)),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CategoryPage(state: state, categoryId: child.id),
            ),
          ),
        );
      },
    );
  }
}
