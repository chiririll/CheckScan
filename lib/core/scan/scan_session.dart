import '../models/receipt_record.dart';
import '../storage/receipt_repository.dart';
import 'native_adapter.dart';
import 'scan_outcome.dart';

/// Scan pipeline: match → dedupe → resolve → persist.
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
    final match = matched.data;
    if (match == null) {
      return ScanOutcome.failed(matched.status, matched.message);
    }
    onMatched?.call();

    final existing = await repository.findByHash(match.storageKey);
    if (existing != null && !existing.canRetry) {
      return ScanOutcome.found(existing);
    }

    final saved = await _resolveAndSave(
      rawQr: rawQr,
      qrHash: match.storageKey,
      adapterId: match.adapterId,
      fallbackLabel: match.label,
      existing: existing,
    );
    return saved.record == null ? ScanOutcome.failed(saved.status, saved.message) : ScanOutcome.found(saved.record!);
  }

  /// Re-resolves a retryable receipt. Null when the provider returned nothing.
  Future<ReceiptRecord?> refresh(ReceiptRecord record) async {
    if (!record.canRetry) return record;
    final saved = await _resolveAndSave(
      rawQr: record.rawQr,
      qrHash: record.qrHash,
      adapterId: record.adapterId,
      existing: record,
      wait: true,
    );
    return saved.record;
  }

  /// Retries every retryable receipt; stops early once the provider rate-limits.
  Future<int> refreshPending() async {
    final pending = (await repository.listAll()).where((row) => row.canRetry).toList();
    var done = 0;
    for (final record in pending) {
      try {
        final updated = await refresh(record);
        if (updated == null) continue;
        done += 1;
        if (updated.lastStatus == statusRateLimited) break;
      } catch (_) {}
    }
    return done;
  }

  Future<({ReceiptRecord? record, int status, String message})> _resolveAndSave({
    required String rawQr,
    required String qrHash,
    required String adapterId,
    ReceiptRecord? existing,
    String fallbackLabel = '',
    bool wait = false,
  }) async {
    final resolved = await adapter.resolve(
      rawQr,
      hint: adapterId,
      remote: true,
      wait: wait,
      current: existing?.payload,
    );
    final payload = resolved.data;
    if (payload == null) return (record: null, status: resolved.status, message: resolved.message);
    final label = payload.label.isNotEmpty ? payload.label : fallbackLabel;
    final record = await repository.upsertParsed(
      id: existing?.id,
      qrHash: qrHash,
      adapterId: adapterId,
      rawQr: rawQr,
      receipt: withProviderLabel(payload.receipt, label),
      lastStatus: resolved.status,
      scannedAt: existing?.scannedAt,
    );
    return (record: record, status: resolved.status, message: resolved.message);
  }
}
