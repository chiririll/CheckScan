import 'package:checkscan/core/models/receipt_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native 200 is ok, everything else with receipt is incomplete', () {
    expect(receiptStatusFromNative(statusOk), ReceiptStatus.ok);
    expect(receiptStatusFromNative(statusIncomplete), ReceiptStatus.incomplete);
    expect(receiptStatusFromNative(statusUnavailable), ReceiptStatus.incomplete);
  });

  test('retry is 206 or 5xx, not 200/401/429', () {
    expect(canRetryStatus(statusIncomplete), isTrue);
    expect(canRetryStatus(statusUnavailable), isTrue);
    expect(canRetryStatus(statusOk), isFalse);
    expect(canRetryStatus(statusNeedsSecret), isFalse);
    expect(canRetryStatus(statusRateLimited), isFalse);
  });
}
