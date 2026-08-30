import '../models/receipt_record.dart';
import '../storage/receipt_repository.dart';
import 'adapter_registry.dart';

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
    AdapterChain? chain,
  }) : chain = chain ?? AdapterChain();

  final ReceiptRepository repository;
  final AdapterChain chain;

  Future<ScanResult> process(
    String rawQr, {
    void Function(String status)? onStatus,
  }) async {
    final match = chain.match(rawQr);
    if (match == null) return ScanResult.unknownFormat();

    final existing = await repository.findByHash(match.storageKey);
    if (existing != null) return ScanResult.found(existing);

    try {
      final receipt = await match.adapter.parse(rawQr, onStatus: onStatus);
      final status = receipt.items.isEmpty ? ReceiptStatus.incomplete : ReceiptStatus.ok;
      final saved = await repository.insertParsed(
        qrHash: match.storageKey,
        adapterId: match.adapter.id,
        rawQr: rawQr,
        receipt: receipt,
        status: status,
      );
      return ScanResult.found(saved);
    } on Object {
      final saved = await repository.insertError(
        qrHash: match.storageKey,
        adapterId: match.adapter.id,
        rawQr: rawQr,
      );
      return ScanResult.found(saved);
    }
  }

  Future<ReceiptRecord?> refresh(ReceiptRecord record, {void Function(String status)? onStatus}) async {
    final adapter = chain.byId(record.adapterId);
    if (adapter == null) return null;
    final receipt = await adapter.parse(record.rawQr, onStatus: onStatus);
    final status = receipt.items.isEmpty ? ReceiptStatus.incomplete : ReceiptStatus.ok;
    final updated = record.copyWith(
      status: status,
      issuedAt: receipt.issuedAt,
      merchantName: receipt.merchantName,
      grandTotal: receipt.grandTotal,
      currency: receipt.currency,
      itemCount: receipt.items.length,
      payload: receipt.encode(),
    );
    await repository.replace(updated);
    return updated;
  }
}
