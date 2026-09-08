import 'item_unit.dart';
import 'unit_parser.dart';

/// Display unit for ₽/ед: mass → kg, volume → l, otherwise the product unit.
ItemUnit? displayUnitOf(ItemUnit? productUnit) {
  return switch (productUnit) {
    ItemUnit.g || ItemUnit.kg => ItemUnit.kg,
    ItemUnit.ml || ItemUnit.l => ItemUnit.l,
    ItemUnit.piece => ItemUnit.piece,
    ItemUnit.pack => ItemUnit.pack,
    null => null,
  };
}

bool _isMass(ItemUnit unit) => unit == ItemUnit.g || unit == ItemUnit.kg;

bool _isVolume(ItemUnit unit) => unit == ItemUnit.ml || unit == ItemUnit.l;

double _toKg(double size, ItemUnit unit) => unit == ItemUnit.g ? size / 1000 : size;

double _toL(double size, ItemUnit unit) => unit == ItemUnit.ml ? size / 1000 : size;

/// Pack size in [to], or null when the units cannot be converted honestly.
double? convertPackSize(double size, {required ItemUnit from, required ItemUnit to}) {
  if (size <= 0) return null;
  if (from == to) return size;
  if (_isMass(from) && _isMass(to)) {
    final kg = _toKg(size, from);
    return to == ItemUnit.g ? kg * 1000 : kg;
  }
  if (_isVolume(from) && _isVolume(to)) {
    final litres = _toL(size, from);
    return to == ItemUnit.ml ? litres * 1000 : litres;
  }
  return null;
}

/// How many display units are in this pack. Null = cannot compute ₽/ед.
double? canonicalPackSize({
  required ItemUnit? productUnit,
  double? unitSize,
  ItemUnit? itemUnit,
}) {
  final display = displayUnitOf(productUnit);
  if (display == null) return null;
  if (display == ItemUnit.piece || display == ItemUnit.pack) {
    final size = unitSize;
    if (size == null || size <= 0) return 1;
    return size;
  }
  final size = unitSize;
  if (size == null || size <= 0) return null;
  final from = itemUnit ?? productUnit;
  if (from == null) return size;
  return convertPackSize(size, from: from, to: display);
}

/// Pack shelf price → ₽ per display unit. Null when pack size is unknown.
double? pricePerUnit({
  required double packPrice,
  required ItemUnit? productUnit,
  double? unitSize,
  ItemUnit? itemUnit,
}) {
  final size = canonicalPackSize(productUnit: productUnit, unitSize: unitSize, itemUnit: itemUnit);
  if (size == null || size <= 0) return null;
  return packPrice / size;
}

double? pricePerUnitForName({
  required double packPrice,
  required ItemUnit? productUnit,
  double? unitSize,
  required String displayName,
}) {
  final parsed = parseItemUnit(displayName);
  return pricePerUnit(
    packPrice: packPrice,
    productUnit: productUnit,
    unitSize: unitSize ?? parsed?.size,
    itemUnit: parsed?.unit,
  );
}
