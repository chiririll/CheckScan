import 'package:flutter/material.dart';

import '../../core/catalog/catalog_category.dart';
import '../../core/catalog/catalog_store.dart';
import '../../core/catalog/category_label.dart';
import '../../l10n/app_localizations.dart';

Future<String?> pickAssignableCategory({
  required BuildContext context,
  required CatalogStore catalog,
  String? currentId,
  bool topsOnly = false,
}) {
  final l10n = AppLocalizations.of(context);
  final items = topsOnly ? catalog.topCategories : catalog.assignableCategories();
  return showModalBottomSheet<String?>(
    context: context,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(l10n.noCategory),
            onTap: () => Navigator.pop(context, ''),
          ),
          for (final category in items)
            ListTile(
              title: Text(_label(category, catalog, l10n)),
              selected: category.id == currentId,
              onTap: () => Navigator.pop(context, category.id),
            ),
        ],
      ),
    ),
  );
}

String _label(CatalogCategory category, CatalogStore catalog, AppLocalizations l10n) {
  final own = categoryTitle(category, l10n);
  if (category.parentId == null) return own;
  final parent = catalog.categoryById(category.parentId!);
  if (parent == null) return own;
  return '${categoryTitle(parent, l10n)} · $own';
}
