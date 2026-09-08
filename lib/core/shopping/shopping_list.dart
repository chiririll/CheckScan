import '../catalog/catalog_position.dart';
import '../catalog/catalog_product.dart';
import '../catalog/catalog_resolver.dart';
import '../catalog/item_unit.dart';
import '../catalog/price_point.dart';
import '../catalog/purchase.dart';
import '../catalog/purchase_cache.dart';
import '../catalog/reference_pack.dart';
import '../catalog/unit_parser.dart';
import '../catalog/unit_price.dart';
import '../merchant/merchant.dart';
import '../models/receipt_record.dart';

class ShoppingLine {
  const ShoppingLine({
    required this.productId,
    required this.name,
    required this.packs,
    required this.packSize,
    required this.unit,
    this.cheaperNetwork,
  });

  final String productId;
  final String name;
  final int packs;
  final double packSize;
  final ItemUnit unit;
  final String? cheaperNetwork;
}

/// Tempo + honest pack size → how many packs to take, and where they are cheaper.
///
/// A product is skipped unless it has a unit and a pack size that can be
/// converted to the display unit. No honest rows → empty list, not guesses.
List<ShoppingLine> buildShoppingList({
  required List<Purchase> purchases,
  required List<CatalogProduct> products,
  required List<CatalogPosition> positions,
  required List<ReceiptRecord> receipts,
  required CatalogResolver resolver,
  required List<Merchant> merchants,
  required String fallbackMerchant,
}) {
  final productById = {for (final product in products) product.id: product};
  final itemsByProduct = <String, List<CatalogPosition>>{};
  for (final item in positions) {
    final productId = item.productId;
    if (productId == null) continue;
    itemsByProduct.putIfAbsent(productId, () => []).add(item);
  }

  final counts = <String, int>{};
  final qty = <String, double>{};
  for (final purchase in purchases) {
    if (productById[purchase.productId] == null) continue;
    counts[purchase.productId] = (counts[purchase.productId] ?? 0) + 1;
    qty[purchase.productId] = (qty[purchase.productId] ?? 0) + purchase.quantity;
  }
  if (counts.isEmpty) return const [];

  final points = collectPricePoints(
    receipts: receipts,
    resolver: resolver,
    merchants: merchants,
    ignoreMerchantIds: ignoreMerchantIdsOf(merchants),
    fallbackMerchant: fallbackMerchant,
  );
  final pointsByProduct = <String, List<PricePoint>>{};
  for (final point in points) {
    pointsByProduct.putIfAbsent(point.productId, () => []).add(point);
  }

  final ranked = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final lines = <ShoppingLine>[];
  for (final entry in ranked) {
    final product = productById[entry.key];
    if (product == null) continue;
    final pack = _honestPack(product, itemsByProduct[product.id] ?? const []);
    if (pack == null) continue;
    final avg = (qty[entry.key] ?? 0) / entry.value;
    final packs = avg <= 0 ? 1 : avg.ceil();
    final networks = cheaperNetworks(pointsByProduct[product.id] ?? const []);
    lines.add(
      ShoppingLine(
        productId: product.id,
        name: product.name,
        packs: packs,
        packSize: pack.size,
        unit: pack.unit,
        cheaperNetwork: networks.isEmpty ? null : networks.first.networkName,
      ),
    );
  }
  return lines;
}

({double size, ItemUnit unit})? _honestPack(CatalogProduct product, List<CatalogPosition> items) {
  final display = displayUnitOf(product.unit);
  if (display == null) return null;
  final ref = referencePack(items: items, productUnit: product.unit);
  if (ref == null) return null;
  final parsed = parseItemUnit(ref.displayName);
  final size = canonicalPackSize(
    productUnit: product.unit,
    unitSize: ref.unitSize ?? parsed?.size,
    itemUnit: parsed?.unit,
  );
  if (size == null || size <= 0) return null;
  return (size: size, unit: display);
}
