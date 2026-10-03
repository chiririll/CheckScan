import 'dart:io';

import 'package:checkscan/core/merchant/merchant_repository.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _seq = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CheckScanDatabase database;
  late MerchantRepository merchants;

  setUp(() {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_merchant_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    merchants = MerchantRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('starts with no merchants', () async {
    expect(await merchants.listAll(), isEmpty);
  });

  test('resolve creates a merchant from the receipt name', () async {
    final id = await merchants.resolve(name: 'DELHAIZE SERBIA DOO BEOGRAD');
    final merchant = (await merchants.listAll()).where((m) => m.id == id).firstOrNull;
    expect(merchant?.name, 'DELHAIZE SERBIA DOO BEOGRAD');
    expect(await merchants.resolve(name: 'DELHAIZE SERBIA DOO BEOGRAD'), id);
  });

  test('a network parent can be set and cleared', () async {
    final store = await merchants.resolve(name: 'Магнит у дома');
    final network = await merchants.resolve(name: 'Магнит');
    await merchants.update(store, parentId: network);
    expect((await merchants.listAll()).firstWhere((m) => m.id == store).parentId, network);
    await merchants.update(store, clearParent: true);
    expect((await merchants.listAll()).firstWhere((m) => m.id == store).parentId, isNull);
  });
}
