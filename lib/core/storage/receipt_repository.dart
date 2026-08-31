import 'package:eq_models/eq_models.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/receipt_record.dart';

class ReceiptRepository {
  ReceiptRepository({this._resolveDbPath});

  final Future<String> Function()? _resolveDbPath;
  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final resolver = _resolveDbPath;
    final path = resolver != null
        ? await resolver()
        : p.join((await getApplicationDocumentsDirectory()).path, 'checkscan.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE receipts (
            id TEXT PRIMARY KEY,
            qr_hash TEXT NOT NULL UNIQUE,
            adapter_id TEXT NOT NULL,
            status TEXT NOT NULL,
            issued_at TEXT,
            merchant_name TEXT,
            grand_total REAL NOT NULL,
            currency TEXT NOT NULL,
            item_count INTEGER NOT NULL,
            payload TEXT NOT NULL,
            scanned_at TEXT NOT NULL,
            raw_qr TEXT NOT NULL,
            last_status INTEGER NOT NULL DEFAULT 200
          )
        ''');
        await db.execute('CREATE UNIQUE INDEX idx_receipts_qr_hash ON receipts(qr_hash)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE receipts ADD COLUMN last_status INTEGER NOT NULL DEFAULT 200');
        }
      },
    );
    return _db!;
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) await db.close();
  }

  Future<ReceiptRecord?> findByHash(String qrHash) async {
    final db = await _database;
    final rows = await db.query('receipts', where: 'qr_hash = ?', whereArgs: [qrHash], limit: 1);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<ReceiptRecord?> findById(String id) async {
    final db = await _database;
    final rows = await db.query('receipts', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<List<ReceiptRecord>> listAll() async {
    final db = await _database;
    final rows = await db.query('receipts', orderBy: 'COALESCE(issued_at, scanned_at) DESC');
    return rows.map(_fromRow).toList();
  }

  Future<ReceiptRecord> upsertParsed({
    String? id,
    required String qrHash,
    required String adapterId,
    required String rawQr,
    required EqReceipt receipt,
    required int lastStatus,
    DateTime? scannedAt,
  }) async {
    final existing = await findByHash(qrHash);
    final record = ReceiptRecord(
      id: existing?.id ?? id ?? const Uuid().v4(),
      qrHash: qrHash,
      adapterId: adapterId,
      status: receiptStatusFromNative(lastStatus),
      issuedAt: receipt.issuedAt,
      merchantName: receipt.merchantName,
      grandTotal: receipt.grandTotal,
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

  Future<void> replace(ReceiptRecord record) => _upsert(record);

  Future<void> deleteById(String id) async {
    final db = await _database;
    await db.delete('receipts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _upsert(ReceiptRecord record) async {
    final db = await _database;
    await db.insert(
      'receipts',
      {
        'id': record.id,
        'qr_hash': record.qrHash,
        'adapter_id': record.adapterId,
        'status': record.status.name,
        'issued_at': record.issuedAt?.toIso8601String(),
        'merchant_name': record.merchantName,
        'grand_total': record.grandTotal,
        'currency': record.currency,
        'item_count': record.itemCount,
        'payload': record.payload,
        'scanned_at': record.scannedAt.toIso8601String(),
        'raw_qr': record.rawQr,
        'last_status': record.lastStatus,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  ReceiptRecord _fromRow(Map<String, Object?> row) {
    final statusName = '${row['status']}';
    final status = ReceiptStatus.values.asNameMap()[statusName] ?? ReceiptStatus.incomplete;
    final lastStatus = (row['last_status'] as num?)?.toInt() ??
        (status == ReceiptStatus.ok ? statusOk : statusIncomplete);
    return ReceiptRecord(
      id: '${row['id']}',
      qrHash: '${row['qr_hash']}',
      adapterId: '${row['adapter_id']}',
      status: status == ReceiptStatus.error ? ReceiptStatus.incomplete : status,
      issuedAt: DateTime.tryParse('${row['issued_at']}'),
      merchantName: row['merchant_name'] as String?,
      grandTotal: (row['grand_total'] as num?)?.toDouble() ?? 0,
      currency: '${row['currency'] ?? ''}',
      itemCount: (row['item_count'] as num?)?.toInt() ?? 0,
      payload: '${row['payload'] ?? ''}',
      scannedAt: DateTime.tryParse('${row['scanned_at']}') ?? DateTime.fromMillisecondsSinceEpoch(0),
      rawQr: '${row['raw_qr'] ?? ''}',
      lastStatus: lastStatus,
    );
  }
}
