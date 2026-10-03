class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.parentId,
    this.icon,
  });

  final String id;
  final String name;
  final String? parentId;
  final int sortOrder;
  final String? icon;

  bool get isTop => parentId == null;
}
