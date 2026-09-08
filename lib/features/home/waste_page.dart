import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/catalog/category_label.dart';
import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/category_page.dart';
import '../catalog/product_page.dart';
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
    if (leaves.isEmpty && tags.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.wasteBlock)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.wasteEmptyTitle, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                Text(l10n.wasteEmptyBody, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wasteBlock)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (leaves.isNotEmpty) ...[
            Text(l10n.wasteByLeaf, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final slice in leaves)
              _WasteTile(
                name: categoryLabel(slice.name, l10n),
                spent: formatMoney(slice.spent, currency),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => CategoryPage(state: state, categoryId: slice.id)),
                ),
              ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.wasteByTag, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final slice in tags)
              _WasteTile(
                name: slice.name,
                spent: formatMoney(slice.spent, currency),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _WasteTagPage(state: state, tagId: slice.id, tagName: slice.name),
                  ),
                ),
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
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE4E4E4)),
        ),
        title: Text(name),
        trailing: Text(spent, style: const TextStyle(fontWeight: FontWeight.w600)),
        onTap: onTap,
      ),
    );
  }
}

class _WasteTagPage extends StatelessWidget {
  const _WasteTagPage({required this.state, required this.tagId, required this.tagName});

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
      body: ListView.separated(
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
  }
}
