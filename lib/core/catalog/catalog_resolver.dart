import 'catalog_category.dart';
import 'catalog_position.dart';
import 'catalog_product.dart';

class CatalogHit {
  const CatalogHit({required this.position, this.product, this.category});

  final CatalogPosition position;
  final CatalogProduct? product;
  final CatalogCategory? category;
}

class CatalogResolver {
  const CatalogResolver({
    this.byRawName = const {},
    this.positions = const {},
    this.products = const {},
    this.categories = const {},
  });

  final Map<String, String> byRawName;
  final Map<String, CatalogPosition> positions;
  final Map<String, CatalogProduct> products;
  final Map<String, CatalogCategory> categories;

  static const empty = CatalogResolver();

  CatalogHit? resolve(String description) {
    final positionId = byRawName[description];
    if (positionId == null) return null;
    final position = positions[positionId];
    if (position == null) return null;
    final product = position.productId == null ? null : products[position.productId!];
    final category = product?.categoryId == null ? null : categories[product!.categoryId!];
    return CatalogHit(position: position, product: product, category: category);
  }

  String topKey(String description) {
    final hit = resolve(description);
    if (hit?.product != null) return hit!.product!.name;
    if (hit != null) return hit.position.displayName;
    return description;
  }

  String cheaperKey(String description) {
    final hit = resolve(description);
    return hit?.position.displayName ?? description;
  }

  String? categoryName(String description) => resolve(description)?.category?.name;

  String? categoryId(String description) => resolve(description)?.category?.id;
}
