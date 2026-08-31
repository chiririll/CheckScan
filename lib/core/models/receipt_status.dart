import 'package:eq_models/eq_models.dart';

enum ReceiptStatus { ok, incomplete, error }

const providerLabelExtension = 'checkscan.provider_label';
const rateLimitedExtension = 'checkscan.rate_limited';
const itemsUnavailableExtension = 'checkscan.items_unavailable';

const statusOk = 200;
const statusIncomplete = 206;
const statusParseError = 400;
const statusNeedsSecret = 401;
const statusUnknownFormat = 415;
const statusRateLimited = 429;
const statusUnavailable = 503;

int statusClass(int status) => status < 100 ? 0 : status ~/ 100;

ReceiptStatus receiptStatusFromNative(int status) {
  if (status == statusOk) return ReceiptStatus.ok;
  return ReceiptStatus.incomplete;
}

bool canRetryStatus(int status) {
  if (status == statusOk || status == statusRateLimited || status == statusNeedsSecret) {
    return false;
  }
  return status == statusIncomplete || statusClass(status) == 5;
}

bool _extensionFlag(EqReceipt receipt, String key) {
  final value = receipt.extensions[key];
  return value == true || value == 'true';
}

EqReceipt withProviderLabel(EqReceipt receipt, String label) {
  if (label.isEmpty) return receipt;
  return receipt.copyWith(
    extensions: {...receipt.extensions, providerLabelExtension: label},
  );
}

bool receiptFlag(EqReceipt receipt, String key) => _extensionFlag(receipt, key);
