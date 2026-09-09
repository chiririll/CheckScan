import 'dart:io';

import 'package:checkscan/core/catalog/catalog_repository.dart';
import 'package:checkscan/core/catalog/catalog_store.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:checkscan/features/catalog/category_picker.dart';
import 'package:checkscan/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _seq = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CheckScanDatabase database;
  late CatalogStore catalog;

  setUp(() async {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_cat_picker_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    catalog = CatalogStore(repository: CatalogRepository(database: database));
    await catalog.reload();
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('product picker is two-step: tops first, then children', (tester) async {
    String? picked;
    await tester.pumpWidget(_app(
      onPick: (context) async {
        picked = await pickAssignableCategory(context: context, catalog: catalog);
      },
    ));
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();

    expect(find.text('Продукты'), findsOneWidget);
    expect(find.text('Кафе'), findsOneWidget);
    expect(find.text('Молочные и яйца'), findsNothing);
    expect(find.textContaining('·'), findsNothing);

    await tester.tap(find.text('Продукты'));
    await tester.pumpAndSettle();
    expect(find.text('Молочные и яйца'), findsOneWidget);
    expect(find.text('Бакалея'), findsOneWidget);

    await tester.tap(find.text('Молочные и яйца'));
    await tester.pumpAndSettle();
    expect(picked, catalog.categories.firstWhere((item) => item.name == '#dairyEggs').id);
  });

  testWidgets('a top without children assigns immediately', (tester) async {
    String? picked;
    await tester.pumpWidget(_app(
      onPick: (context) async {
        picked = await pickAssignableCategory(context: context, catalog: catalog);
      },
    ));
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Кафе'));
    await tester.tap(find.text('Кафе'));
    await tester.pumpAndSettle();
    expect(picked, catalog.categories.firstWhere((item) => item.name == '#cafe').id);
  });

  testWidgets('merchant tops-only never shows leaves', (tester) async {
    String? picked;
    await tester.pumpWidget(_app(
      onPick: (context) async {
        picked = await pickAssignableCategory(context: context, catalog: catalog, topsOnly: true);
      },
    ));
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Продукты'));
    await tester.pumpAndSettle();
    expect(find.text('Молочные и яйца'), findsNothing);
    expect(picked, catalog.categories.firstWhere((item) => item.name == '#products').id);
  });
}

Widget _app({required Future<void> Function(BuildContext context) onPick}) {
  return MaterialApp(
    locale: const Locale('ru'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => onPick(context),
          child: const Text('pick'),
        ),
      ),
    ),
  );
}
