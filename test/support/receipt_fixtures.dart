import 'package:checkscan/core/models/receipt_record.dart';
import 'package:receipt_model/receipt_model.dart';

/// A sale receipt with deterministic defaults. Override only what a test cares about.
Receipt testReceipt({
  String id = 'r1',
  DateTime? issuedAt,
  String currency = 'RUB',
  int scale = 2,
  String type = 'sale',
  String? merchantName = 'Пятёрочка',
  String? taxId,
  int total = 124700,
  List<ReceiptItem> items = const [],
  Map<String, dynamic> extensions = const {},
}) {
  return Receipt(
    id: id,
    issuedAt: issuedAt ?? DateTime(2026, 8, 28, 18, 42),
    currency: currency,
    scale: scale,
    type: type,
    merchantName: merchantName,
    taxId: taxId,
    total: total,
    items: items,
    extensions: extensions,
  );
}

/// Wraps [receipt] the way the scan pipeline stores it: money, scale and counts come from the receipt itself.
ReceiptRecord testRecord(
  Receipt receipt, {
  String? id,
  String? qrHash,
  String adapterId = 'eq_payload',
  ReceiptStatus status = ReceiptStatus.ok,
  String? payload,
  DateTime? scannedAt,
  String rawQr = '{}',
}) {
  final recordId = id ?? receipt.id;
  return ReceiptRecord(
    id: recordId,
    qrHash: qrHash ?? '$adapterId:$recordId',
    adapterId: adapterId,
    status: status,
    issuedAt: receipt.issuedAt,
    merchantName: receipt.merchantName,
    total: receipt.total,
    currency: receipt.currency,
    scale: receipt.scale,
    itemCount: receipt.items.length,
    payload: payload ?? receipt.encode(),
    scannedAt: scannedAt ?? DateTime(2026, 8, 28, 18, 50),
    rawQr: rawQr,
  );
}

const milkItem = ReceiptItem(name: 'Молоко 1 л', quantity: 2, price: 8900, sum: 17800);
