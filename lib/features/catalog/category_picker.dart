import 'package:flutter/material.dart';

import '../../core/catalog/catalog_category.dart';
import '../../core/catalog/catalog_store.dart';
import '../../core/catalog/category_label.dart';
import '../../l10n/app_localizations.dart';

/// Picks an assignable category: tops first, then children of that top.
///
/// A product may hang on a leaf or on a top with no children. Tops-only
/// (merchant envelope) stays a single list.
Future<String?> pickAssignableCategory({
  required BuildContext context,
  required CatalogStore catalog,
  String? currentId,
  bool topsOnly = false,
}) {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CategoryPickerSheet(
      catalog: catalog,
      currentId: currentId,
      topsOnly: topsOnly,
    ),
  );
}

class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({
    required this.catalog,
    required this.currentId,
    required this.topsOnly,
  });

  final CatalogStore catalog;
  final String? currentId;
  final bool topsOnly;

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  CatalogCategory? _parent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showingChildren = _parent != null && !widget.topsOnly;
    final items = showingChildren ? widget.catalog.childrenOf(_parent!.id) : widget.catalog.topCategories;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          if (showingChildren)
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: Text(categoryTitle(_parent!, l10n)),
              onTap: () => setState(() => _parent = null),
            )
          else
            ListTile(
              title: Text(l10n.noCategory),
              selected: widget.currentId == null || widget.currentId!.isEmpty,
              onTap: () => Navigator.pop(context, ''),
            ),
          for (final category in items)
            ListTile(
              title: Text(categoryTitle(category, l10n)),
              selected: category.id == widget.currentId,
              trailing: !widget.topsOnly && !showingChildren && widget.catalog.hasChildren(category.id)
                  ? const Icon(Icons.chevron_right)
                  : null,
              onTap: () => _onTap(category),
            ),
        ],
      ),
    );
  }

  void _onTap(CatalogCategory category) {
    if (widget.topsOnly) {
      Navigator.pop(context, category.id);
      return;
    }
    if (_parent == null && widget.catalog.hasChildren(category.id)) {
      setState(() => _parent = category);
      return;
    }
    Navigator.pop(context, category.id);
  }
}
