import '../models/receipt_record.dart';
import '../storage/receipt_repository.dart';
import 'providers_backend.dart';

class ScanResult {
  const ScanResult({this.record, this.unknown = false});

  final ReceiptRecord? record;
  final bool unknown;

  factory ScanResult.found(ReceiptRecord record) => ScanResult(record: record);
  factory ScanResult.unknownFormat() => const ScanResult(unknown: true);
}

class ScanSession {
  ScanSession({
    required this.repository,
    required this.backend,
  });

  final ReceiptRepository repository;
  final ProvidersBackend backend;

  Future<ScanResult> process(
    String rawQr, {
    void Function(String adapterId)? onMatched,
  }) async {
    final match = await backend.match(rawQr);
    if (match == null) return ScanResult.unknownFormat();
    onMatched?.call(match.adapterId);

    final existing = await repository.findByHash(match.storageKey);
    if (existing != null) return ScanResult.found(existing);

    try {
      final resolved = await backend.resolve(rawQr, hint: match.adapterId);
      final status = resolved.receipt.items.isEmpty ? ReceiptStatus.incomplete : ReceiptStatus.ok;
      final saved = await repository.insertParsed(
        qrHash: match.storageKey,
        adapterId: match.adapterId,
        rawQr: rawQr,
        receipt: resolved.receipt,
        status: status,
      );
      return ScanResult.found(saved);
    } on Object {
      final saved = await repository.insertError(
        qrHash: match.storageKey,
        adapterId: match.adapterId,
        rawQr: rawQr,
      );
      return ScanResult.found(saved);
    }
  }

  Future<ReceiptRecord?> refresh(ReceiptRecord record) async {
    final resolved = await backend.resolve(record.rawQr, hint: record.adapterId);
    final status = resolved.receipt.items.isEmpty ? ReceiptStatus.incomplete : ReceiptStatus.ok;
    final updated = record.copyWith(
      status: status,
      issuedAt: resolved.receipt.issuedAt,
      merchantName: resolved.receipt.merchantName,
      grandTotal: resolved.receipt.grandTotal,
      currency: resolved.receipt.currency,
      itemCount: resolved.receipt.items.length,
      payload: resolved.receipt.encode(),
    );
    await repository.replace(updated);
    return updated;
  }
}
