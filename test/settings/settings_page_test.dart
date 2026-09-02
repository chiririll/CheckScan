import 'package:checkscan/core/app_state.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:checkscan/features/settings/settings_page.dart';
import 'package:checkscan/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scan/fake_native_adapter.dart';

void main() {
  testWidgets('export with no receipts shows a snackbar', (tester) async {
    final state = AppState(
      repository: ReceiptRepository(resolveDbPath: () async => 'unused.db'),
      adapter: FakeNativeAdapter(),
    )..ready = true;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: SettingsPage(state: state),
      ),
    );

    await tester.tap(find.text('Экспорт eQ'));
    await tester.pump();

    expect(find.text('Нет чеков для экспорта'), findsOneWidget);
    expect(find.text('Скоро'), findsNWidgets(2));
  });
}
