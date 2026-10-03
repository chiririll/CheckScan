import 'package:checkscan/core/state/app_state.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:checkscan/features/history/history_page.dart';
import 'package:checkscan/features/receipt_detail/receipt_page.dart';
import 'package:checkscan/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../scan/fake_native_adapter.dart';
import '../support/receipt_fixtures.dart';

class _MemoryRepository extends ReceiptRepository {
  _MemoryRepository() : super(resolveDbPath: () async => 'unused.db');
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  Widget app(Widget home) {
    return MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );
  }

  testWidgets('plus in history opens the form and the lines drive the total', (tester) async {
    final state = AppState(repository: _MemoryRepository(), adapter: FakeNativeAdapter());
    await tester.pumpWidget(app(HistoryPage(state: state)));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Новый чек'), findsOneWidget);

    await tester.tap(find.text('Добавить позицию'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Название'), 'Яблоки');
    await tester.enterText(find.widgetWithText(TextField, 'Кол-во'), '2');
    await tester.enterText(find.widgetWithText(TextField, 'Цена'), '50');
    await tester.pump();

    expect(find.text('100 ₽'), findsNWidgets(2)); // line sum and total
  });

  testWidgets('only a manual receipt offers "Изменить"', (tester) async {
    final manual = testRecord(testReceipt(id: 'm1'), adapterId: 'manual');
    final scanned = testRecord(testReceipt(id: 's1'));
    final state = AppState(repository: _MemoryRepository(), adapter: FakeNativeAdapter())
      ..receipts = [manual, scanned];

    for (final (record, expected) in [(manual, true), (scanned, false)]) {
      await tester.pumpWidget(app(ReceiptPage(state: state, receiptId: record.id)));
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Изменить'), expected ? findsOneWidget : findsNothing);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
    }
  });
}
