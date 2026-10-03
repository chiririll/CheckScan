import 'package:checkscan/app/app.dart';
import 'package:checkscan/core/currency/currency_store.dart';
import 'package:checkscan/core/format/format.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/scan/native_adapter.dart';
import 'package:checkscan/core/settings/onboarding_store.dart';
import 'package:checkscan/core/state/app_state.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:checkscan/features/home/home_period.dart';
import 'package:receipt_model/receipt_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'scan/fake_native_adapter.dart';
import 'support/receipt_fixtures.dart';

AppState _state({
  bool onboardingDone = false,
  List<ReceiptRecord> receipts = const [],
  List<String> currencyOrder = const [],
}) {
  final repository = ReceiptRepository(resolveDbPath: () async => 'unused.db');
  return AppState(
    repository: repository,
    adapter: FakeNativeAdapter(),
    onboarding: OnboardingStore()..done = onboardingDone,
    currencies: CurrencyStore()..order = currencyOrder,
  )
    ..ready = true
    ..receipts = receipts;
}

ReceiptRecord _sampleReceipt({DateTime? issuedAt}) {
  final receipt = testReceipt(issuedAt: issuedAt, items: const [milkItem]);
  return testRecord(receipt, payload: withProviderLabel(receipt, 'EQ').encode());
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  testWidgets('first launch shows onboarding', (tester) async {
    await tester.pumpWidget(CheckScanApp(state: _state()));
    await tester.pump();
    expect(find.text('Чеки всегда под рукой'), findsOneWidget);
  });

  testWidgets('not now finishes onboarding and shows empty home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(CheckScanApp(state: _state()));
    await tester.pump();
    await tester.tap(find.text('Далее'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Далее'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Не сейчас'));
    await tester.pump();
    expect(find.text('Пока нет статистики'), findsOneWidget);
    expect(find.text('Главная'), findsWidgets);
    expect(find.text('История'), findsWidgets);
    expect(find.text('Каталог'), findsNothing);
    expect(find.text('Список'), findsNothing);
  });

  testWidgets('settings lists integrations as soon', (tester) async {
    await tester.pumpWidget(CheckScanApp(state: _state(onboardingDone: true)));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1С'), findsOneWidget);
    expect(find.text('Экспорт чеков'), findsOneWidget);
    expect(find.text('Облако'), findsOneWidget);
    expect(find.text('Скоро'), findsNWidgets(2));
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);
  });

  testWidgets('settings shows provider token from schema label', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = _state(onboardingDone: true);
    state.settingFields = const [SettingField(key: 'ru_fns.token', type: 'secret', label: 'RU')];
    await tester.pumpWidget(CheckScanApp(state: state));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Токен (RU)'), findsOneWidget);
    expect(find.textContaining('proverkacheka'), findsNothing);
  });

  testWidgets('home and history show receipt numbers', (tester) async {
    final now = DateTime.now();
    final currentMonth = _sampleReceipt(issuedAt: DateTime(now.year, now.month, 1, 12));
    await tester.pumpWidget(CheckScanApp(state: _state(onboardingDone: true, receipts: [currentMonth])));
    await tester.pump();
    expect(find.text('Потрачено'), findsOneWidget);
    expect(find.text('Чеков'), findsOneWidget);
    expect(find.text('Магазины'), findsOneWidget);

    await tester.tap(find.text('История'));
    await tester.pump();
    expect(find.text('Пятёрочка'), findsOneWidget);
    expect(find.text('1 товар'), findsOneWidget);
  });

  testWidgets('home splits stats by currency tabs and keeps period shared', (tester) async {
    final now = DateTime.now();
    final issued = DateTime(now.year, now.month, 10, 12);
    final rub = _sampleReceipt(issuedAt: issued);
    final rsdReceipt = Receipt(
      id: 'r2',
      issuedAt: issued,
      currency: 'RSD',
      scale: 2,
      type: 'sale',
      merchantName: 'Maxi',
      total: 50000,
      items: const [ReceiptItem(name: 'Hleb', quantity: 1, price: 50000, sum: 50000)],
    );
    final rsd = ReceiptRecord(
      id: 'r2',
      qrHash: 'eq_payload:r2',
      adapterId: 'eq_payload',
      status: ReceiptStatus.ok,
      issuedAt: issued,
      merchantName: rsdReceipt.merchantName,
      total: rsdReceipt.total,
      currency: rsdReceipt.currency,
      scale: 2,
      itemCount: rsdReceipt.items.length,
      payload: rsdReceipt.encode(),
      scannedAt: issued,
      rawQr: '{}',
    );

    await tester.pumpWidget(CheckScanApp(state: _state(onboardingDone: true, receipts: [rub, rsd], currencyOrder: const ['RUB', 'RSD'])));
    await tester.pump();

    expect(find.text('₽'), findsOneWidget);
    expect(find.text('дин.'), findsOneWidget);
    expect(find.text(formatMoney(124700, scale: 2, currency: 'RUB')), findsOneWidget);

    await tester.tap(find.byTooltip('Предыдущий период'));
    await tester.pump();
    final previousLabel = formatMonthYear(HomePeriod.current(now).previous.asDate);
    expect(find.text(previousLabel), findsOneWidget);
    expect(find.text('Нет чеков за этот месяц'), findsWidgets);

    await tester.tap(find.text('дин.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(previousLabel), findsOneWidget);
    expect(find.text('Нет чеков за этот месяц'), findsWidgets);

    await tester.tap(find.byTooltip('Следующий период'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(formatMonthYear(HomePeriod.current(now).asDate)), findsOneWidget);
    expect(find.text(formatMoney(50000, scale: 2, currency: 'RSD')), findsWidgets);
  });
}
