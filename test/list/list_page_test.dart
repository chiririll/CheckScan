import 'package:checkscan/core/app_state.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:checkscan/features/list/list_page.dart';
import 'package:checkscan/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scan/fake_native_adapter.dart';

void main() {
  testWidgets('list tab is empty until unitSize and product are honest', (tester) async {
    final state = AppState(
      repository: ReceiptRepository(resolveDbPath: () async => 'unused.db'),
      adapter: FakeNativeAdapter(),
    )..ready = true;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ListPage(state: state),
      ),
    );

    expect(find.text('Пока нечего брать'), findsOneWidget);
    expect(find.textContaining('фасовку'), findsOneWidget);
  });
}
