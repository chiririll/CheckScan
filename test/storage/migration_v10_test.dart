import 'dart:io';

import 'package:checkscan/core/storage/database.dart';
import 'package:checkscan/core/storage/migrations/migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Map<String, Object?> _row(String id, {required String issuedAt, required String scannedAt}) {
  return {
    'id': id,
    'qr_hash': 'h:$id',
    'adapter_id': 'manual',
    'status': 'ok',
    'issued_at': issuedAt,
    'currency': 'RSD',
    'total': 100,
    'scale': 2,
    'item_count': 0,
    'payload': '{}',
    'scanned_at': scannedAt,
    'raw_qr': '',
    'last_status': 200,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('v10 rewrites offset-less dates as UTC and leaves UTC ones alone', () async {
    final path = p.join(Directory.systemTemp.path, 'checkscan_v10_utc.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    final old = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 9,
        onCreate: (db, _) => runMigrations(
          db,
          fromExclusive: 0,
          toInclusive: 9,
          steps: [for (final step in checkScanMigrations) if (step.version <= 9) step],
        ),
      ),
    );
    await old.insert('receipts', _row('local', issuedAt: '2026-10-20T20:00:00.000', scannedAt: '2026-10-25T02:30:00.000'));
    await old.insert('receipts', _row('utc', issuedAt: '2026-10-27T18:00:00.000Z', scannedAt: '2026-10-27T18:05:00.000Z'));
    await old.close();

    final database = CheckScanDatabase(resolvePath: () async => path);
    final rows = await (await database.database).query('receipts', orderBy: 'id');
    await database.close();

    final local = rows.firstWhere((r) => r['id'] == 'local');
    expect(local['issued_at'], DateTime(2026, 10, 20, 20).toUtc().toIso8601String());
    expect(local['scanned_at'], DateTime(2026, 10, 25, 2, 30).toUtc().toIso8601String());
    final utc = rows.firstWhere((r) => r['id'] == 'utc');
    expect(utc['issued_at'], '2026-10-27T18:00:00.000Z');
    expect(utc['scanned_at'], '2026-10-27T18:05:00.000Z');
  });
}
