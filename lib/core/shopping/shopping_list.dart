import '../catalog/catalog_resolver.dart';
import '../catalog/model/catalog_position.dart';
import '../catalog/model/catalog_product.dart';
import '../catalog/model/item_unit.dart';
import '../catalog/model/purchase.dart';
import '../catalog/pricing/price_point.dart';
import '../catalog/pricing/reference_pack.dart';
import '../catalog/pricing/unit_price.dart';
import '../catalog/purchase_stats.dart';
import '../catalog/text/unit_parser.dart';
import '../merchant/merchant.dart';
import '../models/receipt_record.dart';
import '../util/collections.dart';

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
  final productById = products.indexBy((product) => product.id);
  final itemsByProduct = positions.where((item) => item.productId != null).groupBy((item) => item.productId!);
  final tallies = tallyPurchases(purchases.where((purchase) => productById.containsKey(purchase.productId)));
  if (tallies.isEmpty) return const [];

  final pointsByProduct = collectPricePoints(
    receipts: receipts,
    resolver: resolver,
    merchants: merchants,
    fallbackMerchant: fallbackMerchant,
  ).groupBy((point) => point.productId);

  final lines = <ShoppingLine>[];
  for (final tally in tallies) {
    final product = productById[tally.productId]!;
    final pack = _honestPack(product, itemsByProduct[product.id] ?? const []);
    if (pack == null) continue;
    final avg = tally.quantity / tally.count;
    final networks = cheaperNetworks(pointsByProduct[product.id] ?? const []);
    lines.add(
      ShoppingLine(
        productId: product.id,
        name: product.name,
        packs: avg <= 0 ? 1 : avg.ceil(),
        packSize: pack.size,
        unit: pack.unit,
        cheaperNetwork: networks.firstOrNull?.networkName,
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
