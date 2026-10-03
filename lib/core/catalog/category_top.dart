import 'model/catalog_category.dart';

/// Walk a shelf to its Savvy envelope (top). Leaves keep the parent; a top stays itself.
CatalogCategory? topCategoryOf({
  required String? categoryId,
  required Map<String, CatalogCategory> byId,
}) {
  if (categoryId == null) return null;
  final category = byId[categoryId];
  if (category == null) return null;
  if (category.isTop) return category;
  final parent = category.parentId == null ? null : byId[category.parentId!];
  return parent ?? category;
}

Map<String, CatalogCategory> categoryIndex(Iterable<CatalogCategory> categories) {
  return {for (final category in categories) category.id: category};
}
