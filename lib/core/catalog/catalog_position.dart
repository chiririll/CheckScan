class CatalogPosition {
  const CatalogPosition({
    required this.id,
    required this.displayName,
    this.productId,
    this.unitSize,
    this.brand,
    this.aliases = const [],
  });

  final String id;
  final String displayName;
  final String? productId;
  final double? unitSize;
  final String? brand;
  final List<String> aliases;

  CatalogPosition copyWith({
    String? displayName,
    String? productId,
    bool clearProduct = false,
    double? unitSize,
    bool clearAmount = false,
    String? brand,
    bool clearBrand = false,
    List<String>? aliases,
  }) {
    return CatalogPosition(
      id: id,
      displayName: displayName ?? this.displayName,
      productId: clearProduct ? null : (productId ?? this.productId),
      unitSize: clearAmount ? null : (unitSize ?? this.unitSize),
      brand: clearBrand ? null : (brand ?? this.brand),
      aliases: aliases ?? this.aliases,
    );
  }
}
