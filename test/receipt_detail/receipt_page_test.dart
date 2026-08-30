import 'package:checkscan/core/app_state.dart';
import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/core/scan/scan_session.dart';
import 'package:checkscan/core/storage/receipt_repository.dart';
import 'package:checkscan/features/receipt_detail/receipt_page.dart';
import 'package:checkscan/l10n/app_localizations.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../scan/fake_providers_backend.dart';

class _FakeRepository extends ReceiptRepository {
  _FakeRepository() : super(resolveDbPath: () async => 'unused.db');

  String? deletedId;

  @override
  Future<void> deleteById(String id) async {
    deletedId = id;
  }

  @override
  Future<List<ReceiptRecord>> listAll() async => const [];
}

ReceiptRecord _sample({Map<String, dynamic>? extensions}) {
  final receipt = EqReceipt(
    id: 'r1',
    issuedAt: DateTime(2026, 8, 28, 18, 42),
    currency: 'RUB',
    receiptType: 'sale',
    merchantName: 'Пятёрочка',
    taxId: '7707083893',
    grandTotal: 1247,
    items: const [EqItem(description: 'Молоко 1 л', quantity: 2, unitPrice: 89, totalPrice: 178)],
    extensions: extensions ?? const {},
  );
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
    payload: receipt.encode(),
    scannedAt: DateTime(2026, 8, 28, 18, 50),
    rawQr: '{}',
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  late _FakeRepository repository;
  late AppState state;

  setUp(() {
    repository = _FakeRepository();
    state = AppState(
      repository: repository,
      session: ScanSession(repository: repository, backend: FakeProvidersBackend()),
    )..receipts = [_sample()];
  });

  Future<void> openReceipt(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReceiptPage(state: state, receiptId: 'r1'),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('delete icon asks for confirmation and cancel keeps the receipt', (tester) async {
    await openReceipt(tester);

    await tester.tap(find.byTooltip('Удалить'));
    await tester.pump();
    expect(find.text('Удалить чек?'), findsOneWidget);
    expect(find.text('Чек исчезнет из истории и статистики.'), findsOneWidget);

    await tester.tap(find.text('Отмена'));
    await tester.pump();
    expect(find.text('Молоко 1 л'), findsOneWidget);
    expect(repository.deletedId, isNull);
    expect(state.receipts, isNotEmpty);
  });

  testWidgets('confirming delete removes the receipt and leaves the page', (tester) async {
    await openReceipt(tester);

    await tester.tap(find.byTooltip('Удалить'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('open'), findsOneWidget);
    expect(find.text('Молоко 1 л'), findsNothing);
    expect(repository.deletedId, 'r1');
    expect(state.receipts, isEmpty);
  });

  testWidgets('metadata stays collapsed until the spoiler is opened', (tester) async {
    state.receipts = [
      _sample(
        extensions: {
          'extra': {'fn': '8710000100905518'},
        },
      ),
    ];
    await openReceipt(tester);

    expect(find.text('Метаданные'), findsOneWidget);
    expect(find.text('fn'), findsNothing);
    expect(find.text('8710000100905518'), findsNothing);

    await tester.tap(find.text('Метаданные'));
    await tester.pumpAndSettle();

    expect(find.text('fn'), findsOneWidget);
    expect(find.text('8710000100905518'), findsOneWidget);
    expect(find.text('ИНН'), findsOneWidget);
    expect(find.text('7707083893'), findsOneWidget);
  });
}
