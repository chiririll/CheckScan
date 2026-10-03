import 'package:receipt_model/receipt_model.dart';

/// ISO 4217 minor-unit digits that differ from 2. Only legacy data needs this:
/// new receipts carry the scale their provider set.
const _isoScale = {'JPY': 0, 'KRW': 0, 'VND': 0, 'BHD': 3, 'KWD': 3, 'OMR': 3, 'TND': 3};

int legacyScale(String currency) => _isoScale[currency.toUpperCase()] ?? 2;

/// Converts a stored eQ 1.0 receipt (`{eq_version, receipt}` or the bare receipt)
/// into the CheckScan format. Used only by the v8 migration.
Receipt receiptFromEq(Map<String, dynamic> json) {
  final body = json['receipt'] is Map ? Map<String, dynamic>.from(json['receipt'] as Map) : json;
  final merchant = body['merchant'] is Map ? Map<String, dynamic>.from(body['merchant'] as Map) : const {};
  final totals = body['totals'] is Map ? Map<String, dynamic>.from(body['totals'] as Map) : const {};
  final currency = '${body['currency'] ?? 'RUB'}';
  final exp = legacyScale(currency);
  final rawItems = body['items'];
  return Receipt(
    id: '${body['id'] ?? ''}',
    issuedAt: DateTime.tryParse('${body['issued_at']}') ?? DateTime.now(),
    currency: currency,
    scale: exp,
    type: '${body['receipt_type'] ?? 'sale'}',
    merchantName: merchant['name']?.toString(),
    taxId: merchant['tax_id']?.toString(),
    total: legacyMinor(totals['grand_total'] ?? totals['total'] ?? body['grand_total'], exp),
    items: [
      if (rawItems is List)
        for (final item in rawItems.whereType<Map>())
          ReceiptItem(
            name: '${item['description'] ?? ''}',
            quantity: (item['quantity'] as num?)?.toDouble() ?? 0,
            price: legacyMinor(item['unit_price'], exp),
            sum: legacyMinor(item['total_price'], exp),
          ),
    ],
    extensions: body['extensions'] is Map ? Map<String, dynamic>.from(body['extensions'] as Map) : const {},
  );
}

/// An old float amount goes through its shortest decimal text ("89.99"),
/// never through multiplication, so 89.99 becomes exactly 8999.
int legacyMinor(Object? value, int exp) {
  if (value == null) return 0;
  return parseMinor('$value', exp) ?? 0;
}
