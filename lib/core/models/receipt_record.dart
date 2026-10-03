import 'dart:convert';

import 'package:eq_models/eq_models.dart';

import 'receipt_status.dart';

export 'receipt_status.dart';

class ReceiptRecord {
  ReceiptRecord({
    required this.id,
    required this.qrHash,
    required this.adapterId,
    required this.status,
    required this.issuedAt,
    required this.merchantName,
    required this.grandTotal,
    required this.currency,
    required this.itemCount,
    required this.payload,
    required this.scannedAt,
    required this.rawQr,
    this.lastStatus = statusOk,
    this.merchantId,
  });

  final String id;
  final String qrHash;
  final String adapterId;
  final ReceiptStatus status;
  final DateTime? issuedAt;
  final String? merchantName;
  final double grandTotal;
  final String currency;
  final int itemCount;
  final String payload;
  final DateTime scannedAt;
  final String rawQr;
  final int lastStatus;
  final String? merchantId;

  EqReceipt? _cached;

  /// When the purchase happened: the receipt date, or the scan time without one.
  DateTime get at => issuedAt ?? scannedAt;

  String displayMerchant(String fallback) {
    final name = merchantName;
    return name == null || name.isEmpty ? fallback : name;
  }

  EqReceipt get receipt {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return _cached = EqReceipt.fromJson(decoded);
      }
      if (decoded is Map) {
        return _cached = EqReceipt.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return _cached = EqReceipt(
      id: id,
      issuedAt: issuedAt ?? scannedAt,
      currency: currency.isEmpty ? 'RUB' : currency,
      receiptType: 'sale',
      grandTotal: grandTotal,
      merchantName: merchantName,
    );
  }

  String get providerLabel {
    final label = receipt.extensions[providerLabelExtension];
    if (label is String && label.isNotEmpty) return label;
    return '';
  }

  bool get canRetry => canRetryStatus(lastStatus);

  bool get missingRemoteItems => status != ReceiptStatus.ok && itemCount == 0;

  bool get itemsUnavailable => receiptFlag(receipt, itemsUnavailableExtension);
}
