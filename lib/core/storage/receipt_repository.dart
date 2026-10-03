import 'package:receipt_model/receipt_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../merchant/merchant_repository.dart';
import '../models/receipt_record.dart';
import '../util/collections.dart';
import 'database.dart';
import 'row.dart';

class ReceiptRepository {
  ReceiptRepository({
    CheckScanDatabase? database,
    Future<String> Function()? resolveDbPath,
    MerchantRepository? merchants,
  }) : this._(database ?? CheckScanDatabase(resolvePath: resolveDbPath), merchants);

  ReceiptRepository._(this.database, MerchantRepository? merchants)
      : merchants = merchants ?? MerchantRepository(database: database);

  final CheckScanDatabase database;
  final MerchantRepository merchants;

  Future<Database> get _db => database.database;

  Future<void> close() => database.close();

  Future<ReceiptRecord?> findByHash(String qrHash) => _findOne('qr_hash = ?', qrHash);

  Future<List<ReceiptRecord>> listAll() async {
    final rows = await (await _db).query('receipts', orderBy: 'COALESCE(issued_at, scanned_at) DESC');
    return rows.map(_fromRow).toList();
  }

  /// Inserts or replaces the receipt stored under [qrHash], keeping its id and scan time.
  Future<ReceiptRecord> upsertParsed({
    String? id,
    required String qrHash,
    required String adapterId,
    required String rawQr,
    required Receipt receipt,
    required int lastStatus,
    DateTime? scannedAt,
  }) async {
    final existing = await findByHash(qrHash);
    final hasMerchant = trimmedOrNull(receipt.merchantName) != null || trimmedOrNull(receipt.taxId) != null;
    final merchantId =
        hasMerchant ? await merchants.resolve(name: receipt.merchantName, taxId: receipt.taxId) : existing?.merchantId;
    final record = ReceiptRecord(
      id: existing?.id ?? id ?? const Uuid().v4(),
      qrHash: qrHash,
      adapterId: adapterId,
      status: receiptStatusFromNative(lastStatus),
      issuedAt: receipt.issuedAt,
      merchantName: receipt.merchantName,
      merchantId: merchantId,
      total: receipt.total,
      scale: receipt.scale,
      currency: receipt.currency,
      itemCount: receipt.items.length,
      payload: receipt.encode(),
      scannedAt: existing?.scannedAt ?? scannedAt ?? DateTime.now(),
      rawQr: rawQr,
      lastStatus: lastStatus,
    );
    await _upsert(record);
    return record;
  }

  Future<void> deleteById(String id) async {
    await (await _db).transaction((txn) async {
      // Legacy catalog cache; the table is kept for old data but must not point at deleted receipts.
      await txn.delete('purchase', where: 'check_id = ?', whereArgs: [id]);
      await txn.delete('receipts', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<ReceiptRecord?> _findOne(String where, String arg) async {
    final rows = await (await _db).query('receipts', where: where, whereArgs: [arg], limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<void> _upsert(ReceiptRecord record) async {
    await (await _db).insert(
      'receipts',
      {
        'id': record.id,
        'qr_hash': record.qrHash,
        'adapter_id': record.adapterId,
        'status': record.status.name,
        'issued_at': record.issuedAt?.toIso8601String(),
        'merchant_name': record.merchantName,
        'total': record.total,
        'scale': record.scale,
        'currency': record.currency,
        'item_count': record.itemCount,
        'payload': record.payload,
        'scanned_at': record.scannedAt.toIso8601String(),
        'raw_qr': record.rawQr,
        'last_status': record.lastStatus,
        'merchant_id': record.merchantId == null ? null : int.tryParse(record.merchantId!),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  ReceiptRecord _fromRow(Map<String, Object?> row) {
    final status = ReceiptStatus.values.asNameMap()[row.str('status')] ?? ReceiptStatus.incomplete;
    return ReceiptRecord(
      id: row.str('id'),
      qrHash: row.str('qr_hash'),
      adapterId: row.str('adapter_id'),
      // Legacy rows may carry `error`; it is shown as incomplete.
      status: status == ReceiptStatus.error ? ReceiptStatus.incomplete : status,
      issuedAt: row.date('issued_at'),
      merchantName: row.optStr('merchant_name'),
      total: row.optInt('total') ?? 0,
      scale: row.optInt('scale') ?? 2,
      currency: row.str('currency'),
      itemCount: row.optInt('item_count') ?? 0,
      payload: row.str('payload'),
      scannedAt: row.date('scanned_at') ?? DateTime.fromMillisecondsSinceEpoch(0),
      rawQr: row.str('raw_qr'),
      lastStatus: row.optInt('last_status') ?? (status == ReceiptStatus.ok ? statusOk : statusIncomplete),
      merchantId: row.optStr('merchant_id'),
    );
  }
}
