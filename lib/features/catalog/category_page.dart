import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/catalog/category_label.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/empty_hint.dart';
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
        final products = [for (final product in state.catalog.products) if (product.categoryId == category.id) product];
        return Scaffold(
          appBar: AppBar(title: Text(categoryTitle(category, l10n))),
          body: products.isEmpty
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
                        MaterialPageRoute<void>(builder: (_) => ProductPage(state: state, productId: product.id)),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
