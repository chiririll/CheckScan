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

  EqReceipt? _cached;

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

  bool get rateLimited => lastStatus == statusRateLimited || receiptFlag(receipt, rateLimitedExtension);

  bool get needsSecret => lastStatus == statusNeedsSecret;

  bool get itemsUnavailable => receiptFlag(receipt, itemsUnavailableExtension);

  ReceiptRecord copyWith({
    ReceiptStatus? status,
    DateTime? issuedAt,
    String? merchantName,
    double? grandTotal,
    String? currency,
    int? itemCount,
    String? payload,
    int? lastStatus,
  }) {
    return ReceiptRecord(
      id: id,
      qrHash: qrHash,
      adapterId: adapterId,
      status: status ?? this.status,
      issuedAt: issuedAt ?? this.issuedAt,
      merchantName: merchantName ?? this.merchantName,
      grandTotal: grandTotal ?? this.grandTotal,
      currency: currency ?? this.currency,
      itemCount: itemCount ?? this.itemCount,
      payload: payload ?? this.payload,
      scannedAt: scannedAt,
      rawQr: rawQr,
      lastStatus: lastStatus ?? this.lastStatus,
    );
  }
}
