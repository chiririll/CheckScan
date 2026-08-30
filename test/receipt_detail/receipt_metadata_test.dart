import 'package:checkscan/core/models/receipt_record.dart';
import 'package:checkscan/features/receipt_detail/receipt_metadata.dart';
import 'package:checkscan/l10n/app_localizations_ru.dart';
import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';

ReceiptRecord _record(EqReceipt receipt, {String rawQr = ''}) {
  return ReceiptRecord(
    id: 'row-1',
    qrHash: 'hash',
    adapterId: 'any',
    status: ReceiptStatus.ok,
    issuedAt: receipt.issuedAt,
    merchantName: receipt.merchantName,
    grandTotal: receipt.grandTotal,
    currency: receipt.currency,
    itemCount: receipt.items.length,
    payload: receipt.encode(),
    scannedAt: DateTime(2026, 8, 28, 18, 50),
    rawQr: rawQr,
  );
}

EqReceipt _base({
  String id = 'r1',
  String receiptType = 'sale',
  String? taxId,
  Map<String, dynamic> extensions = const {},
}) {
  return EqReceipt(
    id: id,
    issuedAt: DateTime(2026, 8, 28, 18, 42),
    currency: 'RUB',
    receiptType: receiptType,
    taxId: taxId,
    grandTotal: 1247,
    extensions: extensions,
  );
}

void main() {
  final l10n = AppLocalizationsRu();

  test('shows eQ fields, flattens extension maps, hides checkscan internals', () {
    final rows = receiptMetadataRows(
      _record(
        _base(
          id: 'eq-1',
          taxId: '7707083893',
          extensions: {
            providerLabelExtension: 'RU',
            rateLimitedExtension: true,
            'checkscan.qr_raw': 'qr-payload',
            'extra': {
              'fn': '8710000100905518',
              'code': '12',
            },
          },
        ),
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
      _record(
        _base(
          id: 'eq-2',
          receiptType: 'refund',
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
