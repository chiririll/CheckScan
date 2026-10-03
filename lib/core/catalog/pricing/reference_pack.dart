import '../model/catalog_position.dart';
import '../model/item_unit.dart';
import '../text/unit_parser.dart';
import 'unit_price.dart';

class RankedPack {
  const RankedPack({required this.item, required this.size});

  final CatalogPosition item;
  final double size;
}

/// Largest pack in the product's display unit. Ties keep [items] order
/// (caller should pass latest-seen first if "последняя" matters).
CatalogPosition? referencePack({
  required Iterable<CatalogPosition> items,
  required ItemUnit? productUnit,
  DateTime? Function(CatalogPosition item)? lastSeen,
}) {
  RankedPack? best;
  DateTime? bestSeen;
  CatalogPosition? latest;
  DateTime? latestSeen;

  for (final item in items) {
    final parsed = parseItemUnit(item.displayName);
    final size = canonicalPackSize(
      productUnit: productUnit,
      unitSize: item.unitSize ?? parsed?.size,
      itemUnit: parsed?.unit,
    );
    final seen = lastSeen?.call(item);
    if (seen != null && (latestSeen == null || seen.isAfter(latestSeen))) {
      latest = item;
      latestSeen = seen;
    }
    if (size == null) continue;
    final betterSize = best == null || size > best.size;
    final newerTie = best != null && size == best.size && seen != null && (bestSeen == null || seen.isAfter(bestSeen));
    if (betterSize || newerTie) {
      best = RankedPack(item: item, size: size);
      bestSeen = seen;
    }
  }
  return best?.item ?? latest ?? (items.isEmpty ? null : items.first);
}
