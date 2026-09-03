import 'item_unit.dart';

class CatalogPosition {
  const CatalogPosition({
    required this.id,
    required this.displayName,
    this.productId,
    this.unit,
    this.unitSize,
    this.aliases = const [],
  });

  final String id;
  final String displayName;
  final String? productId;
  final ItemUnit? unit;
  final double? unitSize;
  final List<String> aliases;

  CatalogPosition copyWith({
    String? displayName,
    String? productId,
    bool clearProduct = false,
    ItemUnit? unit,
    double? unitSize,
    bool clearUnit = false,
    List<String>? aliases,
  }) {
    return CatalogPosition(
      id: id,
      displayName: displayName ?? this.displayName,
      productId: clearProduct ? null : (productId ?? this.productId),
      unit: clearUnit ? null : (unit ?? this.unit),
      unitSize: clearUnit ? null : (unitSize ?? this.unitSize),
      aliases: aliases ?? this.aliases,
    );
  }
}
