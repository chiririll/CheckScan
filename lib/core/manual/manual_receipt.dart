import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:eq_models/eq_models.dart';

import '../catalog/catalog_position.dart';
import '../catalog/catalog_product.dart';
import '../catalog/reference_pack.dart';

const manualProviderId = 'manual';

class ManualLine {
  const ManualLine({
    required this.productId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String description;
  final double quantity;
  final double unitPrice;

  double get totalPrice => quantity * unitPrice;

  EqItem get asItem => EqItem(
        description: description,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
      );
}

EqReceipt buildManualReceipt({
  required String id,
  required DateTime issuedAt,
  required String merchantName,
  required List<EqItem> items,
  String currency = 'RUB',
}) {
  final total = items.fold<double>(0, (sum, item) => sum + item.totalPrice);
  return EqReceipt(
    id: id,
    issuedAt: issuedAt,
    currency: currency,
    receiptType: 'sale',
    merchantName: merchantName,
    items: items,
    grandTotal: total,
  );
}

/// Hash of the first saved eQ. Later edits must keep this key so the row stays one check.
String manualStorageKey(EqReceipt receipt) {
  final digest = sha256.convert(utf8.encode(receipt.encode()));
  return '$manualProviderId:${digest.toString()}';
}

/// Prefer an existing cashier title so ingest aliases back to the product.
String lineDescriptionFor({
  required CatalogProduct product,
  required Iterable<CatalogPosition> positions,
}) {
  final own = [for (final item in positions) if (item.productId == product.id) item];
  if (own.isEmpty) return product.name;
  return referencePack(items: own, productUnit: product.unit)?.displayName ?? own.first.displayName;
}
