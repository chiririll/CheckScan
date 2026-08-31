import 'package:checkscan/app.dart';
import 'package:checkscan/core/app_state.dart';
import 'package:checkscan/core/format.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/scan/providers_backend.dart';
import 'package:checkscan/core/scan/scan_session.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:checkscan/features/home/home_stats.dart';
import 'package:eq_models/eq_models.dart';

import 'scan/fake_providers_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppState _state({bool onboardingDone = false, List<ReceiptRecord> receipts = const []}) {
  final repository = ReceiptRepository(resolveDbPath: () async => 'unused.db');
  return AppState(
    repository: repository,
    session: ScanSession(repository: repository, backend: FakeProvidersBackend()),
  )
    ..ready = true
    ..onboardingDone = onboardingDone
    ..receipts = receipts;
}

ReceiptRecord _sampleReceipt() {
  final receipt = EqReceipt(
    id: 'r1',
    issuedAt: DateTime(2026, 8, 28, 18, 42),
    currency: 'RUB',
    receiptType: 'sale',
    merchantName: 'Пятёрочка',
    grandTotal: 1247,
    items: const [EqItem(description: 'Молоко 1 л', quantity: 2, unitPrice: 89, totalPrice: 178)],
  );
  final labeled = withProviderLabel(receipt, 'EQ');
  return ReceiptRecord(
    id: 'r1',
    qrHash: 'eq_payload:r1',
    adapterId: 'eq_payload',
    status: ReceiptStatus.ok,
    issuedAt: receipt.issuedAt,
    merchantName: receipt.merchantName,
    grandTotal: receipt.grandTotal,
    currency: receipt.currency,
    itemCount: receipt.items.length,
    payload: labeled.encode(),
    scannedAt: DateTime(2026, 8, 28, 18, 50),
    rawQr: '{}',
  );
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
    expect(find.text('История'), findsOneWidget);
  });

  testWidgets('settings lists integrations as soon', (tester) async {
    await tester.pumpWidget(CheckScanApp(state: _state(onboardingDone: true)));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1С'), findsOneWidget);
    expect(find.text('Экспорт eQ'), findsOneWidget);
    expect(find.text('Облако'), findsOneWidget);
    expect(find.text('Скоро'), findsNWidgets(3));
  });

  testWidgets('settings shows provider token from schema label', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = _state(onboardingDone: true);
    state.secretSpecs = const [ProviderSecretSpec(key: 'ru_fns.token', label: 'RU')];
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
    final currentMonth = _sampleReceipt().copyWith(issuedAt: DateTime(now.year, now.month, 1, 12));
    await tester.pumpWidget(CheckScanApp(state: _state(onboardingDone: true, receipts: [currentMonth])));
    await tester.pump();
    expect(find.text('Потрачено'), findsOneWidget);
    expect(find.text('Чеков'), findsOneWidget);
    expect(find.text('Молоко 1 л'), findsOneWidget);

    await tester.tap(find.text('История'));
    await tester.pump();
    expect(find.text('Пятёрочка'), findsOneWidget);
    expect(find.text('1 товар'), findsOneWidget);
  });

  testWidgets('home splits stats by currency tabs and keeps period shared', (tester) async {
    final now = DateTime.now();
    final issued = DateTime(now.year, now.month, 10, 12);
    final rub = _sampleReceipt().copyWith(issuedAt: issued);
    final rsdReceipt = EqReceipt(
      id: 'r2',
      issuedAt: issued,
      currency: 'RSD',
      receiptType: 'sale',
      merchantName: 'Maxi',
      grandTotal: 500,
      items: const [EqItem(description: 'Hleb', quantity: 1, unitPrice: 500, totalPrice: 500)],
    );
    final rsd = ReceiptRecord(
      id: 'r2',
      qrHash: 'eq_payload:r2',
      adapterId: 'eq_payload',
      status: ReceiptStatus.ok,
      issuedAt: issued,
      merchantName: rsdReceipt.merchantName,
      grandTotal: rsdReceipt.grandTotal,
      currency: rsdReceipt.currency,
      itemCount: rsdReceipt.items.length,
      payload: rsdReceipt.encode(),
      scannedAt: issued,
      rawQr: '{}',
    );

    await tester.pumpWidget(CheckScanApp(state: _state(onboardingDone: true, receipts: [rub, rsd])));
    await tester.pump();

    expect(find.text('₽'), findsOneWidget);
    expect(find.text('дин.'), findsOneWidget);
    expect(find.text(formatMoney(1247, 'RUB')), findsOneWidget);
    expect(find.text('Молоко 1 л'), findsOneWidget);

    await tester.tap(find.byTooltip('Предыдущий период'));
    await tester.pump();
    final previousLabel = formatMonthYear(HomePeriod.current(now).previous.asDate);
    expect(find.text(previousLabel), findsOneWidget);
    expect(find.text('Нет чеков за этот месяц'), findsWidgets);

    await tester.tap(find.text('дин.'));
    await tester.pumpAndSettle();
    expect(find.text(previousLabel), findsOneWidget);
    expect(find.text('Нет чеков за этот месяц'), findsWidgets);

    await tester.tap(find.byTooltip('Следующий период'));
    await tester.pumpAndSettle();
    expect(find.text(formatMonthYear(HomePeriod.current(now).asDate)), findsOneWidget);
    expect(find.text(formatMoney(500, 'RSD')), findsWidgets);
    expect(find.text('Hleb'), findsOneWidget);
  });
}
