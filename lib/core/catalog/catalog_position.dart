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

  CatalogPosition copyWith({
    String? displayName,
    String? productId,
    bool clearProduct = false,
    double? unitSize,
    bool clearAmount = false,
    List<String>? aliases,
    List<CatalogTag>? tags,
  }) {
    return CatalogPosition(
      id: id,
      displayName: displayName ?? this.displayName,
      productId: clearProduct ? null : (productId ?? this.productId),
      unitSize: clearAmount ? null : (unitSize ?? this.unitSize),
      aliases: aliases ?? this.aliases,
      tags: tags ?? this.tags,
    );
  }
}
