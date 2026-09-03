class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isSeed,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool isSeed;
}
