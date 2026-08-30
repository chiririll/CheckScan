import 'dart:convert';

import 'package:eq_models/eq_models.dart';

enum ReceiptStatus { ok, error, incomplete }

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
    switch (adapterId) {
      case 'ru_fns':
        return 'RU';
      case 'rs_purs':
        return 'RS';
      case 'eq_payload':
        return 'eQ';
      default:
        return adapterId;
    }
  }

  bool get canRetry => status == ReceiptStatus.error || status == ReceiptStatus.incomplete;

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
