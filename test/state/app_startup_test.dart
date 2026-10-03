import 'dart:async';
import 'dart:io';

import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/scan/native_adapter.dart';
import 'package:checkscan/core/state/app_state.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../scan/fake_native_adapter.dart';

/// Native library that answers the settings schema only when told to.
class _SlowAdapter extends FakeNativeAdapter {
  final schema = Completer<List<SettingField>>();

  @override
  Future<List<SettingField>> settings() => schema.future;
}

int _seq = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CheckScanDatabase database;
  late ReceiptRepository receipts;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_startup_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    receipts = ReceiptRepository(database: database);
  });

  tearDown(() => database.close());

  Future<void> saveReceipt() {
    return receipts.upsertParsed(
      qrHash: 'shop:1',
      adapterId: 'test',
      rawQr: '{}',
      receipt: EqReceipt(
        id: 'r1',
        issuedAt: DateTime(2026, 8, 1),
        currency: 'RUB',
        receiptType: 'sale',
        merchantName: 'Магнит',
        grandTotal: 90,
        items: const [EqItem(description: 'Молоко 1л', quantity: 1, unitPrice: 90, totalPrice: 90)],
      ),
      lastStatus: statusOk,
    );
  }

  test('becomes ready before the native library answers', () async {
    await saveReceipt();
    final adapter = _SlowAdapter();
    final state = AppState(repository: receipts, adapter: adapter);
    final readyFired = Completer<void>();
    state.addListener(() {
      if (state.ready && !readyFired.isCompleted) readyFired.complete();
    });

    final loading = state.load();
    await readyFired.future;

    expect(state.receipts, hasLength(1));
    expect(state.settingFields, isEmpty);

    adapter.schema.complete(const [SettingField(key: 'k', type: 'secret', label: 'RU')]);
    await loading;
    expect(state.settingFields.single.key, 'k');
    state.dispose();
  });
}
