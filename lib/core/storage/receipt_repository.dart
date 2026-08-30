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
      version: 1,
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
            raw_qr TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE UNIQUE INDEX idx_receipts_qr_hash ON receipts(qr_hash)');
      },
    );
    return _db!;
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

  Future<ReceiptRecord> insertParsed({
    required String qrHash,
    required String adapterId,
    required String rawQr,
    required EqReceipt receipt,
    required ReceiptStatus status,
  }) async {
    final record = ReceiptRecord(
      id: receipt.id.isNotEmpty ? receipt.id : const Uuid().v4(),
      qrHash: qrHash,
      adapterId: adapterId,
      status: status,
      issuedAt: receipt.issuedAt,
      merchantName: receipt.merchantName,
      grandTotal: receipt.grandTotal,
      currency: receipt.currency,
      itemCount: receipt.items.length,
      payload: receipt.encode(),
      scannedAt: DateTime.now(),
      rawQr: rawQr,
    );
    await _upsert(record);
    return record;
  }

  Future<ReceiptRecord> insertError({
    required String qrHash,
    required String adapterId,
    required String rawQr,
    EqReceipt? partial,
  }) async {
    final fallback = partial ??
        EqReceipt(
          id: const Uuid().v4(),
          issuedAt: DateTime.now(),
          currency: 'RUB',
          receiptType: 'sale',
          grandTotal: 0,
          extensions: {'checkscan.qr_raw': rawQr},
        );
    return insertParsed(
      qrHash: qrHash,
      adapterId: adapterId,
      rawQr: rawQr,
      receipt: fallback,
      status: ReceiptStatus.error,
    );
  }

  Future<void> replace(ReceiptRecord record) => _upsert(record);

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
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  ReceiptRecord _fromRow(Map<String, Object?> row) {
    return ReceiptRecord(
      id: row['id'] as String,
      qrHash: row['qr_hash'] as String,
      adapterId: row['adapter_id'] as String,
      status: ReceiptStatus.values.byName(row['status'] as String),
      issuedAt: DateTime.tryParse('${row['issued_at']}'),
      merchantName: row['merchant_name'] as String?,
      grandTotal: (row['grand_total'] as num).toDouble(),
      currency: row['currency'] as String,
      itemCount: row['item_count'] as int,
      payload: row['payload'] as String,
      scannedAt: DateTime.parse(row['scanned_at'] as String),
      rawQr: row['raw_qr'] as String,
    );
  }
}
