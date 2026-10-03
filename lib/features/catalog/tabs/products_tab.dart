import 'package:flutter/material.dart';

import '../../../core/state/app_state.dart';
import '../../../core/util/collections.dart';
import '../../../l10n/app_localizations.dart';
import '../../labels/category_label.dart';
import '../../labels/unit_labels.dart';
import '../../widgets/card_tile.dart';
import '../../widgets/empty_hint.dart';
import '../../widgets/navigation.dart';
import '../product_page.dart';

class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key, required this.state, required this.query});

  final AppState state;
  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = state.catalog;
    if (catalog.products.isEmpty) {
      return EmptyHint(title: l10n.catalogEmptyProducts, body: l10n.catalogEmptyProductsBody);
    }
    final products = filterByQuery(catalog.products, query, (product) => [product.name]);
    if (products.isEmpty) {
      return EmptyHint(title: l10n.catalogEmptySearch, body: l10n.catalogSearch);
    }
    return CardList(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final category = product.categoryId == null ? null : catalog.categoryById(product.categoryId!);
        return CardTile(
          title: product.name,
          subtitle: [
            if (category != null) categoryTitle(category, l10n),
            if (product.unit != null) unitLabel(product.unit, l10n),
          ].join(' · '),
          onTap: () => pushPage<void>(context, ProductPage(state: state, productId: product.id)),
        );
      },
    );
  }
}
