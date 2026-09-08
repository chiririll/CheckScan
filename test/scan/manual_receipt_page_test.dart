import 'package:checkscan/core/app_state.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:checkscan/features/scan/manual_receipt_page.dart';
import 'package:checkscan/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_native_adapter.dart';

void main() {
  testWidgets('manual receipt asks for a merchant before save', (tester) async {
    final state = AppState(
      repository: ReceiptRepository(resolveDbPath: () async => 'unused.db'),
      adapter: FakeNativeAdapter(),
    )..ready = true;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ManualReceiptPage(state: state),
      ),
    );

    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    expect(find.text('Укажите магазин'), findsOneWidget);
  });

  testWidgets('manual receipt asks for lines after a merchant is set', (tester) async {
    final state = AppState(
      repository: ReceiptRepository(resolveDbPath: () async => 'unused.db'),
      adapter: FakeNativeAdapter(),
    )..ready = true;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ManualReceiptPage(state: state),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Рынок');
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    expect(find.text('Добавьте хотя бы одну строку'), findsOneWidget);
  });
}
