import 'dart:convert';

const receiptFormat = 'checkscan.receipt';
const receiptFormatVersion = 1;

/// One receipt line. [price] and [sum] count 10^-scale units of the receipt's currency; [quantity] may be fractional.
class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.sum,
  });

  final String name;
  final double quantity;
  final int price;
  final int sum;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: '${json['name'] ?? ''}',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      price: _int(json['price']),
      sum: _int(json['sum']),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity, 'price': price, 'sum': sum};
}

/// CheckScan receipt JSON (`format: checkscan.receipt`).
///
/// Money fields are integers counting 10^-[scale] units of [currency]. The provider
/// that produced the receipt sets [scale]; it is never derived from the currency.
class Receipt {
  const Receipt({
    required this.id,
    required this.issuedAt,
    required this.currency,
    required this.scale,
    required this.total,
    this.type = 'sale',
    this.merchantName,
    this.taxId,
    this.items = const [],
    this.extensions = const {},
  });

  final String id;
  final DateTime issuedAt;
  final String currency;
  final int scale;
  final String type;
  final String? merchantName;
  final String? taxId;
  final List<ReceiptItem> items;
  final int total;
  final Map<String, dynamic> extensions;

  /// True when [json] declares this format.
  static bool isReceiptJson(Object? json) => json is Map && json['format'] == receiptFormat;

  /// Throws [FormatException] for any other format or a receipt without `scale`.
  factory Receipt.fromJson(Map<String, dynamic> json) {
    if (!isReceiptJson(json)) throw const FormatException('not a checkscan.receipt');
    final scale = json['scale'];
    if (scale is! int) throw const FormatException('checkscan.receipt without scale');
    final merchant = json['merchant'] is Map ? Map<String, dynamic>.from(json['merchant'] as Map) : const {};
    final rawItems = json['items'];
    return Receipt(
      id: '${json['id'] ?? ''}',
      issuedAt: DateTime.tryParse('${json['issued_at']}') ?? DateTime.now(),
      currency: '${json['currency'] ?? 'RUB'}',
      scale: scale,
      type: '${json['type'] ?? 'sale'}',
      merchantName: merchant['name']?.toString(),
      taxId: merchant['tax_id']?.toString(),
      items: rawItems is List
          ? [for (final item in rawItems.whereType<Map>()) ReceiptItem.fromJson(Map<String, dynamic>.from(item))]
          : const [],
      total: _int(json['total']),
      extensions: json['extensions'] is Map ? Map<String, dynamic>.from(json['extensions'] as Map) : const {},
    );
  }

  factory Receipt.decode(String raw) => Receipt.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));

  Map<String, dynamic> toJson() => {
        'format': receiptFormat,
        'version': receiptFormatVersion,
        'id': id,
        'issued_at': issuedAt.toUtc().toIso8601String(),
        'currency': currency,
        'scale': scale,
        'type': type,
        'merchant': {
          'name': ?merchantName,
          'tax_id': ?taxId,
        },
        'total': total,
        'items': [for (final item in items) item.toJson()],
        'extensions': extensions,
      };

  String encode() => jsonEncode(toJson());

  Receipt copyWith({Map<String, dynamic>? extensions}) {
    return Receipt(
      id: id,
      issuedAt: issuedAt,
      currency: currency,
      scale: scale,
      total: total,
      type: type,
      merchantName: merchantName,
      taxId: taxId,
      items: items,
      extensions: extensions ?? this.extensions,
    );
  }
}

/// Money fields are integers; anything else is a malformed amount and reads as 0.
int _int(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;
