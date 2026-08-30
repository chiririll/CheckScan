import 'dart:convert';

import 'package:eq_models/eq_models.dart';

enum ReceiptStatus { ok, error, incomplete }

const providerLabelExtension = 'checkscan.provider_label';
const rateLimitedExtension = 'checkscan.rate_limited';
const itemsUnavailableExtension = 'checkscan.items_unavailable';

bool _extensionFlag(EqReceipt receipt, String key) {
  final value = receipt.extensions[key];
  return value == true || value == 'true';
}

ReceiptStatus statusFromReceipt(EqReceipt receipt) {
  if (receipt.items.isNotEmpty) return ReceiptStatus.ok;
  if (_extensionFlag(receipt, rateLimitedExtension)) return ReceiptStatus.incomplete;
  if (_extensionFlag(receipt, itemsUnavailableExtension)) return ReceiptStatus.ok;
  return ReceiptStatus.incomplete;
}

EqReceipt withProviderLabel(EqReceipt receipt, String label) {
  if (label.isEmpty) return receipt;
  return receipt.copyWith(
    extensions: {...receipt.extensions, providerLabelExtension: label},
  );
}

class ReceiptRecord {
  const ReceiptRecord({
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

  EqReceipt get receipt => EqReceipt.fromJson(jsonDecode(payload) as Map<String, dynamic>);

  String get providerLabel {
    final label = receipt.extensions[providerLabelExtension];
    if (label is String && label.isNotEmpty) return label;
    return '';
  }

  bool get canRetry => status == ReceiptStatus.error || status == ReceiptStatus.incomplete;

  bool get missingRemoteItems => canRetry && itemCount == 0;

  bool get rateLimited => _extensionFlag(receipt, rateLimitedExtension);

  bool get itemsUnavailable => _extensionFlag(receipt, itemsUnavailableExtension);

  ReceiptRecord copyWith({
    ReceiptStatus? status,
    DateTime? issuedAt,
    String? merchantName,
    double? grandTotal,
    String? currency,
    int? itemCount,
    String? payload,
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
    );
  }
}
