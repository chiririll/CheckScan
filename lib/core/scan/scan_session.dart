import '../models/receipt_record.dart';
import '../storage/receipt_repository.dart';
import 'native_adapter.dart';
import 'scan_outcome.dart';

class ScanSession {
  ScanSession({
    required this.repository,
    required this.adapter,
  });

  final ReceiptRepository repository;
  final NativeAdapter adapter;

  Future<ScanOutcome> process(
    String rawQr, {
    void Function()? onMatched,
  }) async {
    final matched = await adapter.match(rawQr);
    if (matched.status == statusUnknownFormat) {
      return ScanOutcome.unknownFormat(message: matched.message);
    }
    if (matched.data == null) {
      return ScanOutcome.failed(matched.status, matched.message);
    }
    onMatched?.call();

    final existing = await repository.findByHash(matched.data!.storageKey);
    if (existing != null && !existing.canRetry) {
      return ScanOutcome.found(existing);
    }

    final resolved = await adapter.resolve(
      rawQr,
      hint: matched.data!.adapterId,
      remote: true,
      current: existing?.payload,
    );
    final payload = resolved.data;
    if (payload == null) {
      return ScanOutcome.failed(resolved.status, resolved.message);
    }
    final label = payload.label.isNotEmpty ? payload.label : matched.data!.label;
    final receipt = withProviderLabel(payload.receipt, label);
    final saved = await repository.upsertParsed(
      id: existing?.id,
      qrHash: matched.data!.storageKey,
      adapterId: matched.data!.adapterId,
      rawQr: rawQr,
      receipt: receipt,
      lastStatus: resolved.status,
      scannedAt: existing?.scannedAt,
    );
    return ScanOutcome.found(saved);
  }

  Future<ReceiptRecord?> refresh(ReceiptRecord record) async {
    if (!record.canRetry) return record;
    final resolved = await adapter.resolve(
      record.rawQr,
      hint: record.adapterId,
      remote: true,
      wait: true,
      current: record.payload,
    );
    final payload = resolved.data;
    if (payload == null) return null;
    final receipt = withProviderLabel(payload.receipt, payload.label);
    return repository.upsertParsed(
      id: record.id,
      qrHash: record.qrHash,
      adapterId: record.adapterId,
      rawQr: record.rawQr,
      receipt: receipt,
      lastStatus: resolved.status,
      scannedAt: record.scannedAt,
    );
  }

  Future<int> refreshPending({
    void Function(int done, int total)? onProgress,
  }) async {
    final pending = (await repository.listAll()).where((row) => row.canRetry).toList();
    var done = 0;
    for (final record in pending) {
      try {
        final updated = await refresh(record);
        if (updated != null) {
          done += 1;
          onProgress?.call(done, pending.length);
          if (updated.lastStatus == statusRateLimited) {
            break;
          }
        }
      } catch (_) {}
    }
    return done;
  }
}
