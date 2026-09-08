import '../merchant/merchant.dart';
import '../models/receipt_record.dart';
import 'catalog_position.dart';
import 'catalog_product.dart';
import 'catalog_resolver.dart';
import 'item_unit.dart';
import 'reference_pack.dart';
import 'unit_price.dart';

class PricePoint {
  const PricePoint({
    required this.productId,
    required this.itemId,
    required this.at,
    required this.currency,
    required this.networkId,
    required this.networkName,
    required this.packPrice,
    this.perUnit,
    this.unit,
  });

  final String productId;
  final String itemId;
  final DateTime at;
  final String currency;
  final String networkId;
  final String networkName;
  final double packPrice;
  final double? perUnit;
  final ItemUnit? unit;
}

class NetworkPrice {
  const NetworkPrice({required this.networkId, required this.networkName, required this.perUnit});

  final String networkId;
  final String networkName;
  final double perUnit;
}

Merchant? _merchantById(Iterable<Merchant> merchants, String? id) {
  if (id == null) return null;
  for (final merchant in merchants) {
    if (merchant.id == id) return merchant;
  }
  return null;
}

({String id, String name}) networkOf({
  required ReceiptRecord receipt,
  required Iterable<Merchant> merchants,
  required String fallback,
}) {
  final merchant = _merchantById(merchants, receipt.merchantId);
  if (merchant == null) {
    final name = receipt.merchantName ??
        (receipt.providerLabel.isNotEmpty ? receipt.providerLabel : fallback);
    return (id: receipt.merchantId ?? name, name: name);
  }
  final parent = _merchantById(merchants, merchant.parentId);
  return (id: merchant.networkId, name: parent?.name ?? merchant.name);
}

List<PricePoint> collectPricePoints({
  required Iterable<ReceiptRecord> receipts,
  required CatalogResolver resolver,
  required Iterable<Merchant> merchants,
  required Set<String> ignoreMerchantIds,
  required String fallbackMerchant,
}) {
  final points = <PricePoint>[];
  for (final receipt in receipts) {
    if (receipt.merchantId != null && ignoreMerchantIds.contains(receipt.merchantId)) continue;
    final network = networkOf(receipt: receipt, merchants: merchants, fallback: fallbackMerchant);
    final at = receipt.issuedAt ?? receipt.scannedAt;
    for (final line in receipt.receipt.items) {
      final hit = resolver.resolve(line.description);
      final product = hit?.product;
      if (product == null) continue;
      final item = hit!.position;
      final perUnit = pricePerUnitForName(
        packPrice: line.unitPrice,
        productUnit: product.unit,
        unitSize: item.unitSize,
        displayName: item.displayName,
      );
      points.add(
        PricePoint(
          productId: product.id,
          itemId: item.id,
          at: at,
          currency: receipt.currency,
          networkId: network.id,
          networkName: network.name,
          packPrice: line.unitPrice,
          perUnit: perUnit,
          unit: displayUnitOf(product.unit),
        ),
      );
    }
  }
  points.sort((a, b) => b.at.compareTo(a.at));
  return points;
}

List<PricePoint> pointsForProduct(Iterable<PricePoint> points, String productId, {String? currency}) {
  return [
    for (final point in points)
      if (point.productId == productId && (currency == null || point.currency == currency)) point,
  ];
}

/// Latest honest ₽/ед of the reference pack; otherwise latest convertible line.
PricePoint? headlinePrice({
  required Iterable<PricePoint> productPoints,
  required Iterable<CatalogPosition> items,
  required CatalogProduct product,
}) {
  final ranked = [for (final point in productPoints) if (point.perUnit != null) point];
  if (ranked.isEmpty) return null;
  final lastSeen = <String, DateTime>{};
  for (final point in ranked) {
    final current = lastSeen[point.itemId];
    if (current == null || point.at.isAfter(current)) lastSeen[point.itemId] = point.at;
  }
  final ref = referencePack(
    items: [for (final item in items) if (item.productId == product.id) item],
    productUnit: product.unit,
    lastSeen: (item) => lastSeen[item.id],
  );
  if (ref != null) {
    for (final point in ranked) {
      if (point.itemId == ref.id) return point;
    }
  }
  return ranked.first;
}

List<NetworkPrice> cheaperNetworks(Iterable<PricePoint> productPoints) {
  final latest = <String, PricePoint>{};
  for (final point in productPoints) {
    if (point.perUnit == null) continue;
    final current = latest[point.networkId];
    if (current == null || point.at.isAfter(current.at)) latest[point.networkId] = point;
  }
  final list = [
    for (final point in latest.values)
      NetworkPrice(networkId: point.networkId, networkName: point.networkName, perUnit: point.perUnit!),
  ]..sort((a, b) => a.perUnit.compareTo(b.perUnit));
  return list;
}

double? priceShift(Iterable<PricePoint> productPoints) {
  final ranked = [for (final point in productPoints) if (point.perUnit != null) point];
  if (ranked.length < 2) return null;
  final newest = ranked.first.perUnit!;
  final previous = ranked[1].perUnit!;
  if (previous == 0) return null;
  return (newest - previous) / previous;
}
