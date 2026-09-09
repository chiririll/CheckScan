import 'dart:io';

import 'package:checkscan/core/app_state.dart';
import 'package:checkscan/core/catalog/assist_clipboard.dart';
import 'package:checkscan/core/catalog/catalog_repository.dart';
import 'package:checkscan/core/catalog/catalog_store.dart';
import 'package:checkscan/core/storage/database.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:checkscan/features/catalog/assist_actions.dart';
import 'package:checkscan/features/catalog/assist_paste_sheet.dart';
import 'package:checkscan/features/catalog/assist_review_page.dart';
import 'package:checkscan/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../scan/fake_native_adapter.dart';

const _realLlmReply = '''
### Фасоль

* 25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM

### Айвар

* 28011: AJVAR DOMA\uFFFDI LJUTI BA\uFFFD BA\uFFFD 350G/KOM

### Печенье

* 28130: KEKS NOBLICE THINS BANINI 170G/KOM
* Biskvit Jaffa 300g/KOM
* Jaffa kolaci brownie 75g/KOM
''';

const _realLlmHtml = '''
<h3>Фасоль</h3>
<ul>
<li>25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM</li>
</ul>
<h3>Айвар</h3>
<ul>
<li>28011: AJVAR DOMA\uFFFDI LJUTI BA\uFFFD BA\uFFFD 350G/KOM</li>
</ul>
<h3>Печенье</h3>
<ul>
<li>28130: KEKS NOBLICE THINS BANINI 170G/KOM</li>
<li>Biskvit Jaffa 300g/KOM</li>
<li>Jaffa kolaci brownie 75g/KOM</li>
</ul>
''';

const _strippedPlain = '''
Фасоль
25016: PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM
Айвар
28011: AJVAR DOMA\uFFFDI LJUTI BA\uFFFD BA\uFFFD 350G/KOM
Печенье
28130: KEKS NOBLICE THINS BANINI 170G/KOM
Biskvit Jaffa 300g/KOM
Jaffa kolaci brownie 75g/KOM
''';

int _seq = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CheckScanDatabase database;
  late AppState state;

  setUp(() async {
    _seq += 1;
    final path = p.join(Directory.systemTemp.path, 'checkscan_assist_actions_$_seq.db');
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    database = CheckScanDatabase(resolvePath: () async => path);
    final catalog = CatalogRepository(database: database);
    await catalog.ingest(const [
      'PASULJ CRVENI  400G LIM. BONDUELLE KONZERVA/KOM',
      'Хлеб дарницкий',
    ]);
    state = AppState(
      repository: ReceiptRepository(database: database),
      adapter: FakeNativeAdapter(),
      catalog: CatalogStore(repository: catalog),
    );
    await state.catalog.reload();
  });

  tearDown(() async {
    assistClipboardLoader = loadAssistClipboard;
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    messenger.setMockMethodCallHandler(const MethodChannel(assistClipboardChannelName), null);
    await database.close();
  });

  Future<void> tapPaste(WidgetTester tester, String? clipboard) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return clipboard == null ? null : <String, dynamic>{'text': clipboard};
      }
      return null;
    });
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(assistClipboardChannelName),
      (call) async {
        if (call.method == 'getClip') {
          return <String, dynamic>{'plain': clipboard ?? '', 'html': null};
        }
        return null;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => pasteAssistReply(context, state),
              child: const Text('paste'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('paste'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  testWidgets('paste of a real LLM reply opens review even when some lines miss', (tester) async {
    await tapPaste(tester, _realLlmReply);
    expect(find.byType(AssistReviewPage), findsOneWidget);
    expect(find.text('Фасоль'), findsOneWidget);
    expect(find.text('Айвар'), findsOneWidget);
    expect(find.text('Печенье'), findsOneWidget);
    expect(find.text('Не удалось разобрать ответ'), findsNothing);
    expect(find.text('Не удалось сопоставить'), findsOneWidget);
  });

  testWidgets('unreadable clipboard opens a paste field, not review', (tester) async {
    await tapPaste(tester, 'просто пояснение без товаров');
    expect(find.byType(AssistReviewPage), findsNothing);
    expect(find.byKey(assistPasteFieldKey), findsOneWidget);
    expect(find.text('Не удалось разобрать ответ'), findsOneWidget);
  });

  testWidgets('empty clipboard opens a paste field with a different error', (tester) async {
    await tapPaste(tester, '  \n');
    expect(find.byType(AssistReviewPage), findsNothing);
    expect(find.byKey(assistPasteFieldKey), findsOneWidget);
    expect(find.text('Буфер пуст'), findsOneWidget);
    expect(find.text('Не удалось разобрать ответ'), findsNothing);
  });

  testWidgets('pasting the sample into the field opens review', (tester) async {
    await tapPaste(tester, null);
    expect(find.byKey(assistPasteFieldKey), findsOneWidget);
    await tester.enterText(find.byKey(assistPasteFieldKey), _realLlmReply);
    await tester.tap(find.byKey(assistPasteSubmitKey));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(AssistReviewPage), findsOneWidget);
    expect(find.text('Фасоль'), findsOneWidget);
    expect(find.text('Айвар'), findsOneWidget);
    expect(find.text('Печенье'), findsOneWidget);
  });

  testWidgets('HTML clipboard with stripped plain opens review', (tester) async {
    assistClipboardLoader = () async => const AssistClipData(plain: _strippedPlain, html: _realLlmHtml);
    await tapPaste(tester, _strippedPlain);
    expect(find.byType(AssistReviewPage), findsOneWidget);
    expect(find.text('Фасоль'), findsOneWidget);
    expect(find.text('Айвар'), findsOneWidget);
    expect(find.text('Печенье'), findsOneWidget);
    expect(find.text('Не удалось разобрать ответ'), findsNothing);
  });

  testWidgets('stripped plain without HTML stays on the paste field', (tester) async {
    assistClipboardLoader = () async => const AssistClipData(plain: _strippedPlain);
    await tapPaste(tester, _strippedPlain);
    expect(find.byType(AssistReviewPage), findsNothing);
    expect(find.byKey(assistPasteFieldKey), findsOneWidget);
    expect(find.text('Не удалось разобрать ответ'), findsOneWidget);
  });

  testWidgets('confirm rereads HTML clipboard when the field is stripped', (tester) async {
    var clip = const AssistClipData(plain: _strippedPlain);
    assistClipboardLoader = () async => clip;
    await tapPaste(tester, _strippedPlain);
    expect(find.byKey(assistPasteFieldKey), findsOneWidget);
    clip = const AssistClipData(plain: _strippedPlain, html: _realLlmHtml);
    await tester.tap(find.byKey(assistPasteSubmitKey));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(AssistReviewPage), findsOneWidget);
    expect(find.text('Фасоль'), findsOneWidget);
    expect(find.text('Айвар'), findsOneWidget);
    expect(find.text('Печенье'), findsOneWidget);
  });
}
