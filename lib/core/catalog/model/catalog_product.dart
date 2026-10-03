import 'catalog_tag.dart';
import 'item_unit.dart';
import 'product_kind.dart';

class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    this.categoryId,
    this.unit,
    this.kind = ProductKind.good,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String? categoryId;
  final ItemUnit? unit;
  final ProductKind kind;
  final List<CatalogTag> tags;
}
