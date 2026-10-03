import 'package:checkscan/core/models/receipt_status.dart';
import 'package:checkscan/features/receipt_detail/receipt_metadata.dart';
import 'package:checkscan/l10n/app_localizations_ru.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/receipt_fixtures.dart';

void main() {
  final l10n = AppLocalizationsRu();

  test('shows receipt fields, flattens extension maps, hides checkscan internals', () {
    final rows = receiptMetadataRows(
      testRecord(
        testReceipt(
          id: 'eq-1',
          taxId: '7707083893',
          extensions: {
            providerLabelExtension: 'RU',
            'checkscan.rate_limited': true,
            'checkscan.qr_raw': 'qr-payload',
            'extra': {
              'fn': '8710000100905518',
              'code': '12',
            },
          },
        ),
        rawQr: '',
      ),
      l10n,
    );

    expect(
      {for (final row in rows) row.label: row.value},
      {
        'ИНН': '7707083893',
        'Тип': 'Покупка',
        'ID': 'eq-1',
        'fn': '8710000100905518',
        'code': '12',
        'QR': 'qr-payload',
      },
    );
  });

  test('skips nested lists and falls back to raw QR', () {
    final rows = receiptMetadataRows(
      testRecord(
        testReceipt(
          id: 'eq-2',
          type: 'refund',
          extensions: {
            'extra': {
              'note': 'ok',
              'lines': [
                {'name': 'hidden'},
              ],
            },
          },
        ),
        rawQr: 'raw-qr',
      ),
      l10n,
    );
    final byLabel = {for (final row in rows) row.label: row.value};

    expect(byLabel['Тип'], 'Возврат');
    expect(byLabel['note'], 'ok');
    expect(byLabel['QR'], 'raw-qr');
    expect(rows.any((row) => row.value.contains('hidden')), isFalse);
  });
}
