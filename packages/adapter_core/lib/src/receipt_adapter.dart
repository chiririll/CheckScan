import 'eq_models.dart';

abstract class ReceiptAdapter {
  String get id;

  /// `null` — not this format; otherwise a canonical hash (no adapter prefix).
  String? canHandle(String rawQr);

  Future<EqReceipt> parse(
    String rawQr, {
    void Function(String status)? onStatus,
  });
}
