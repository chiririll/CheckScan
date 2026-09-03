import 'catalog_tag.dart';

class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    this.categoryId,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String? categoryId;
  final List<CatalogTag> tags;

  CatalogProduct copyWith({
    String? name,
    String? categoryId,
    bool clearCategory = false,
    List<CatalogTag>? tags,
  }) {
    return CatalogProduct(
      id: id,
      name: name ?? this.name,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      tags: tags ?? this.tags,
    );
  }
}
