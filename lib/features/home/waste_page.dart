import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/format/format.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/category_page.dart';
import '../catalog/product_page.dart';
import '../labels/category_label.dart';
import '../widgets/card_tile.dart';
import '../widgets/centered_message.dart';
import '../widgets/navigation.dart';
import 'home_dashboard.dart';

class WastePage extends StatelessWidget {
  const WastePage({
    super.key,
    required this.state,
    required this.leaves,
    required this.tags,
    required this.currency,
  });

  final AppState state;
  final List<WasteSlice> leaves;
  final List<WasteSlice> tags;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wasteBlock)),
      body: leaves.isEmpty && tags.isEmpty
          ? CenteredMessage(title: l10n.wasteEmptyTitle, body: l10n.wasteEmptyBody)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (leaves.isNotEmpty) ...[
                  Text(l10n.wasteByLeaf, style: AppText.title),
                  const SizedBox(height: 8),
                  for (final slice in leaves)
                    _WasteTile(
                      name: categoryLabel(slice.name, l10n),
                      spent: formatMoney(slice.spent, currency),
                      onTap: () => pushPage<void>(context, CategoryPage(state: state, categoryId: slice.id)),
                    ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(l10n.wasteByTag, style: AppText.title),
                  const SizedBox(height: 8),
                  for (final slice in tags)
                    _WasteTile(
                      name: slice.name,
                      spent: formatMoney(slice.spent, currency),
                      onTap: () => pushPage<void>(context, _TagProductsPage(state: state, tagId: slice.id, tagName: slice.name)),
                    ),
                ],
              ],
            ),
    );
  }
}

class _WasteTile extends StatelessWidget {
  const _WasteTile({required this.name, required this.spent, required this.onTap});

  final String name;
  final String spent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CardTile(title: name, trailing: Text(spent, style: AppText.title), onTap: onTap),
    );
  }
}

class _TagProductsPage extends StatelessWidget {
  const _TagProductsPage({required this.state, required this.tagId, required this.tagName});

  final AppState state;
  final String tagId;
  final String tagName;

  @override
  Widget build(BuildContext context) {
    final products = [
      for (final product in state.catalog.products)
        if (product.tags.any((tag) => tag.id == tagId)) product,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(tagName)),
      body: CardList(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return CardTile(
            title: product.name,
            onTap: () => pushPage<void>(context, ProductPage(state: state, productId: product.id)),
          );
        },
      ),
    );
  }
}
