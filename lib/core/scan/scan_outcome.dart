import '../models/receipt_record.dart';

class ScanOutcome {
  const ScanOutcome._({this.record, this.status = statusOk, this.message = '', this.unknown = false});

  final ReceiptRecord? record;
  final int status;
  final String message;
  final bool unknown;

  factory ScanOutcome.found(ReceiptRecord record) => ScanOutcome._(record: record, status: record.lastStatus);

  factory ScanOutcome.unknownFormat({String message = ''}) {
    return ScanOutcome._(unknown: true, status: statusUnknownFormat, message: message);
  }

  factory ScanOutcome.failed(int status, String message) {
    return ScanOutcome._(status: status, message: message);
  }
}
