import 'package:eq_models/eq_models.dart';

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
    void Function()? onMatched,
  }) async {
    final match = await backend.match(rawQr);
    if (match == null) return ScanResult.unknownFormat();
    onMatched?.call();

    final existing = await repository.findByHash(match.storageKey);
    if (existing != null) return ScanResult.found(existing);

    try {
      final resolved = await backend.resolve(rawQr, hint: match.adapterId, remote: true);
      final label = resolved.label.isNotEmpty ? resolved.label : match.label;
      final receipt = withProviderLabel(resolved.receipt, label);
      final status = receipt.items.isEmpty ? ReceiptStatus.incomplete : ReceiptStatus.ok;
      final saved = await repository.insertParsed(
        qrHash: match.storageKey,
        adapterId: match.adapterId,
        rawQr: rawQr,
        receipt: receipt,
        status: status,
      );
      return ScanResult.found(saved);
    } on Object {
      final saved = await repository.insertError(
        qrHash: match.storageKey,
        adapterId: match.adapterId,
        rawQr: rawQr,
        partial: withProviderLabel(
          EqReceipt(
            id: '',
            issuedAt: DateTime.now(),
            currency: 'RUB',
            receiptType: 'sale',
            grandTotal: 0,
            extensions: {'checkscan.qr_raw': rawQr},
          ),
          match.label,
        ),
      );
      return ScanResult.found(saved);
    }
  }

  Future<ReceiptRecord?> refresh(ReceiptRecord record) async {
    final resolved = await backend.resolve(record.rawQr, hint: record.adapterId, remote: true, wait: true);
    final receipt = withProviderLabel(resolved.receipt, resolved.label);
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

  Future<int> refreshPending({
    void Function(int done, int total)? onProgress,
  }) async {
    final pending = (await repository.listAll()).where((row) => row.canRetry).toList();
    var done = 0;
    for (final record in pending) {
      onProgress?.call(done, pending.length);
      try {
        final updated = await refresh(record);
        done += 1;
        if (updated?.rateLimited == true) {
          break;
        }
      } catch (_) {
        done += 1;
      }
    }
    return done;
  }
}
