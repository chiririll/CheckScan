import 'package:receipt_model/receipt_model.dart';

import '../manual/manual_receipt.dart';
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
    required this.total,
    required this.scale,
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
  /// Receipt total, counting 10^-[scale] units of [currency].
  final int total;

  /// Decimal digits of [total], as set by the provider.
  final int scale;
  final String currency;
  final int itemCount;
  final String payload;
  final DateTime scannedAt;
  final String rawQr;
  final int lastStatus;
  final String? merchantId;

  Receipt? _cached;

  /// When the purchase happened: the receipt date, or the scan time without one.
  DateTime get at => issuedAt ?? scannedAt;

  String displayMerchant(String fallback) {
    final name = merchantName;
    return name == null || name.isEmpty ? fallback : name;
  }

  /// Parsed [payload]; a broken payload falls back to the indexed columns.
  Receipt get receipt {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      return _cached = Receipt.decode(payload);
    } catch (_) {
      return _cached = Receipt(
        id: id,
        issuedAt: at,
        currency: currency.isEmpty ? 'RUB' : currency,
        scale: scale,
        total: total,
        merchantName: merchantName,
      );
    }
  }

  String get providerLabel {
    final label = receipt.extensions[providerLabelExtension];
    if (label is String && label.isNotEmpty) return label;
    return '';
  }

  bool get canRetry => canRetryStatus(lastStatus);

  bool get isRefund => receipt.type == 'refund';

  /// The user can change this receipt's data. Only hand-typed receipts: a scanned one comes from its provider.
  bool get isEditable => adapterId == manualAdapterId;

  /// [total] as it moves money: a refund gives it back.
  int get signedTotal => isRefund ? -total : total;

  bool get missingRemoteItems => status != ReceiptStatus.ok && itemCount == 0 && !itemsUnavailable;

  bool get itemsUnavailable => receiptFlag(receipt, itemsUnavailableExtension);
}
