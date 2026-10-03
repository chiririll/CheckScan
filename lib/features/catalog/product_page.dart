import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/catalog/model/catalog_category.dart';
import '../../core/catalog/model/catalog_product.dart';
import '../../core/catalog/model/product_kind.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../labels/category_label.dart';
import '../widgets/dialogs.dart';
import '../widgets/navigation.dart';
import '../widgets/unit_dropdown.dart';
import 'catalog_nav.dart';
import 'catalog_trail.dart';
import 'category_picker.dart';
import 'product_item_search.dart';
import 'product_prices.dart';
import 'product_receipts_page.dart';
import 'widgets/position_card.dart';
import 'widgets/tag_wrap.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key, required this.state, required this.productId, this.fromCategoryId});

  final AppState state;
  final String productId;

  /// Set when opened from a category, to build the breadcrumb through it.
  final String? fromCategoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final catalog = state.catalog;
        final product = catalog.productById(productId);
        if (product == null) {
          return Scaffold(appBar: AppBar(title: Text(l10n.catalogProducts)));
        }
        final fromCategory = fromCategoryId == null ? null : catalog.categoryById(fromCategoryId!);
        final category = product.categoryId == null ? null : catalog.categoryById(product.categoryId!);
        return Scaffold(
          appBar: CatalogAppBar(
            title: product.name,
            ancestors: _crumbs(context, fromCategory),
            actions: [
              CatalogAction(label: l10n.productReceipts, onSelected: () => _openReceipts(context)),
              CatalogAction(label: l10n.deleteProduct, destructive: true, onSelected: () => _delete(context)),
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
                  if (name != null) await catalog.updateProduct(product.id, name: name);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.productCategory),
                subtitle: Text(category == null ? l10n.noCategory : categoryTitle(category, l10n)),
                onTap: () => _pickCategory(context, product),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.productReceipts),
                onTap: () => _openReceipts(context),
              ),
              UnitDropdownTile(
                value: product.unit,
                onChanged: (unit) => unit == null
                    ? catalog.updateProduct(product.id, clearUnit: true)
                    : catalog.updateProduct(product.id, unit: unit),
              ),
              _KindTile(product: product, onChanged: (kind) => catalog.updateProduct(product.id, kind: kind)),
              const SizedBox(height: 8),
              Text(l10n.productTags, style: AppText.title),
              const SizedBox(height: 8),
              TagWrap(
                tags: product.tags,
                onAdd: (name) => catalog.addTag(product.id, name),
                onRemove: (tagId) => catalog.removeTag(product.id, tagId),
              ),
              ProductPrices(state: state, product: product),
              const SizedBox(height: 16),
              Text(l10n.itemsSection, style: AppText.title),
              const SizedBox(height: 8),
              ProductItemSearch(state: state, productId: product.id),
              const SizedBox(height: 8),
              for (final position in catalog.positionsOf(product.id))
                PositionCard(state: state, position: position, product: product),
            ],
          ),
        );
      },
    );
  }

  List<CatalogCrumb> _crumbs(BuildContext context, CatalogCategory? fromCategory) {
    final l10n = AppLocalizations.of(context);
    return [
      CatalogCrumb(label: l10n.catalogTitle, onTap: () => openCatalog(context, state)),
      if (fromCategory != null) ...[
        CatalogCrumb(label: l10n.catalogCategories, onTap: () => openCatalog(context, state, tab: CatalogTab.categories)),
        CatalogCrumb(label: categoryTitle(fromCategory, l10n), onTap: () => Navigator.pop(context)),
      ] else
        CatalogCrumb(label: l10n.catalogProducts, onTap: () => openCatalog(context, state, tab: CatalogTab.products)),
    ];
  }

  void _openReceipts(BuildContext context) {
    pushPage<void>(context, ProductReceiptsPage(state: state, productId: productId));
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmAction(
      context,
      title: l10n.deleteProductTitle,
      body: l10n.deleteProductBody,
      confirm: l10n.deleteProduct,
    );
    if (!ok || !context.mounted) return;
    await state.catalog.deleteProduct(productId);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _pickCategory(BuildContext context, CatalogProduct product) async {
    final selected = await pickAssignableCategory(context: context, catalog: state.catalog, currentId: product.categoryId);
    if (selected == null) return;
    await state.catalog.updateProduct(
      product.id,
      categoryId: selected.isEmpty ? null : selected,
      clearCategory: selected.isEmpty,
    );
  }
}

class _KindTile extends StatelessWidget {
  const _KindTile({required this.product, required this.onChanged});

  final CatalogProduct product;
  final ValueChanged<ProductKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.productKind),
      trailing: DropdownButton<ProductKind>(
        value: product.kind,
        underline: const SizedBox.shrink(),
        items: [
          DropdownMenuItem(value: ProductKind.good, child: Text(l10n.productKindGood)),
          DropdownMenuItem(value: ProductKind.service, child: Text(l10n.productKindService)),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}
