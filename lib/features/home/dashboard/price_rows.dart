import '../../../core/catalog/model/catalog_position.dart';
import '../../../core/catalog/model/catalog_product.dart';
import '../../../core/catalog/model/item_unit.dart';
import '../../../core/catalog/pricing/price_point.dart';
import '../../../core/util/collections.dart';

/// Product with the widest price spread between networks, for the home card.
class PriceTeaser {
  const PriceTeaser({
    required this.productId,
    required this.productName,
    required this.perUnit,
    required this.unit,
    required this.networkName,
    this.shift,
  });

  final String productId;
  final String productName;
  final double perUnit;
  final ItemUnit unit;
  final String networkName;
  final double? shift;
}

class PriceRow {
  const PriceRow({
    required this.productId,
    required this.productName,
    required this.perUnit,
    required this.unit,
    required this.networkName,
    this.shift,
    this.networks = const [],
  });

  final String productId;
  final String productName;
  final double perUnit;
  final ItemUnit unit;
  final String networkName;
  final double? shift;
  final List<NetworkPrice> networks;
}

/// One row per product with an honest unit price; most compared products first.
List<PriceRow> buildPriceRows({
  required List<PricePoint> points,
  required Map<String, CatalogProduct> products,
  required List<CatalogPosition> positions,
}) {
  final rows = <PriceRow>[];
  for (final MapEntry(key: productId, value: productPoints) in points.groupBy((point) => point.productId).entries) {
    final product = products[productId];
    if (product == null) continue;
    final headline = headlinePrice(productPoints: productPoints, items: positions, product: product);
    final perUnit = headline?.perUnit;
    final unit = headline?.unit;
    if (perUnit == null || unit == null) continue;
    final networks = cheaperNetworks(productPoints);
    rows.add(
      PriceRow(
        productId: product.id,
        productName: product.name,
        perUnit: perUnit,
        unit: unit,
        networkName: networks.firstOrNull?.networkName ?? headline!.networkName,
        shift: priceShift(productPoints),
        networks: networks,
      ),
    );
  }
  rows.sort((a, b) {
    final cmp = b.networks.length.compareTo(a.networks.length);
    if (cmp != 0) return cmp;
    return a.productName.toLowerCase().compareTo(b.productName.toLowerCase());
  });
  return rows;
}

PriceTeaser? priceTeaserOf(List<PriceRow> rows) {
  if (rows.isEmpty) return null;
  var best = rows.first;
  for (final row in rows.skip(1)) {
    if (_spread(row) > _spread(best)) best = row;
  }
  return PriceTeaser(
    productId: best.productId,
    productName: best.productName,
    perUnit: best.networks.firstOrNull?.perUnit ?? best.perUnit,
    unit: best.unit,
    networkName: best.networkName,
    shift: best.shift,
  );
}

double _spread(PriceRow row) {
  if (row.networks.length < 2) return 0;
  return row.networks.last.perUnit - row.networks.first.perUnit;
}
