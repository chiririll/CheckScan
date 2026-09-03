import 'catalog_tag.dart';
import 'item_unit.dart';

class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    this.categoryId,
    this.unit,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String? categoryId;
  final ItemUnit? unit;
  final List<CatalogTag> tags;

  CatalogProduct copyWith({
    String? name,
    String? categoryId,
    bool clearCategory = false,
    ItemUnit? unit,
    bool clearUnit = false,
    List<CatalogTag>? tags,
  }) {
    return CatalogProduct(
      id: id,
      name: name ?? this.name,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      unit: clearUnit ? null : (unit ?? this.unit),
      tags: tags ?? this.tags,
    );
  }
}
