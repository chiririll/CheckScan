import 'catalog_tag.dart';

class CatalogPosition {
  const CatalogPosition({
    required this.id,
    required this.displayName,
    this.productId,
    this.unitSize,
    this.aliases = const [],
    this.tags = const [],
  });

  final String id;
  final String displayName;
  final String? productId;
  final double? unitSize;
  final List<String> aliases;
  final List<CatalogTag> tags;
}
