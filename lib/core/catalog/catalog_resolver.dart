import '../util/collections.dart';
import 'model/catalog_category.dart';
import 'model/catalog_position.dart';
import 'model/catalog_product.dart';

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

  /// Raw cashier names come from each position's aliases.
  factory CatalogResolver.from({
    required Iterable<CatalogCategory> categories,
    required Iterable<CatalogProduct> products,
    required Iterable<CatalogPosition> positions,
  }) {
    return CatalogResolver(
      byRawName: {
        for (final position in positions)
          for (final alias in position.aliases) alias: position.id,
      },
      positions: positions.indexBy((position) => position.id),
      products: products.indexBy((product) => product.id),
      categories: categories.indexBy((category) => category.id),
    );
  }

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

  String? categoryName(String description) => resolve(description)?.category?.name;
}
