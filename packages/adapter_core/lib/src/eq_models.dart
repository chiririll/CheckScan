import 'dart:convert';

class EqItem {
  const EqItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  factory EqItem.fromJson(Map<String, dynamic> json) {
    return EqItem(
      description: (json['description'] ?? '').toString(),
      quantity: _num(json['quantity']),
      unitPrice: _num(json['unit_price']),
      totalPrice: _num(json['total_price']),
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
      };
}

class EqReceipt {
  const EqReceipt({
    required this.id,
    required this.issuedAt,
    required this.currency,
    required this.receiptType,
    required this.grandTotal,
    this.merchantName,
    this.taxId,
    this.items = const [],
    this.extensions = const {},
  });

  final String id;
  final DateTime issuedAt;
  final String currency;
  final String receiptType;
  final String? merchantName;
  final String? taxId;
  final List<EqItem> items;
  final double grandTotal;
  final Map<String, dynamic> extensions;

  factory EqReceipt.fromJson(Map<String, dynamic> json) {
    final receipt = (json['receipt'] is Map)
        ? Map<String, dynamic>.from(json['receipt'] as Map)
        : json;
    final merchant = receipt['merchant'] is Map
        ? Map<String, dynamic>.from(receipt['merchant'] as Map)
        : const <String, dynamic>{};
    final totals = receipt['totals'] is Map
        ? Map<String, dynamic>.from(receipt['totals'] as Map)
        : const <String, dynamic>{};
    final rawItems = receipt['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => EqItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <EqItem>[];
    return EqReceipt(
      id: (receipt['id'] ?? '').toString(),
      issuedAt: DateTime.tryParse('${receipt['issued_at']}') ?? DateTime.now(),
      currency: (receipt['currency'] ?? 'RUB').toString(),
      receiptType: (receipt['receipt_type'] ?? 'sale').toString(),
      merchantName: merchant['name']?.toString(),
      taxId: merchant['tax_id']?.toString(),
      items: items,
      grandTotal: _num(totals['grand_total'] ?? totals['total'] ?? receipt['grand_total']),
      extensions: receipt['extensions'] is Map
          ? Map<String, dynamic>.from(receipt['extensions'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'eq_version': '1.0.0',
        'receipt': {
          'id': id,
          'issued_at': issuedAt.toUtc().toIso8601String(),
          'currency': currency,
          'receipt_type': receiptType,
          'merchant': {
            if (merchantName != null) 'name': merchantName,
            if (taxId != null) 'tax_id': taxId,
          },
          'items': items.map((e) => e.toJson()).toList(),
          'totals': {'grand_total': grandTotal},
          'extensions': extensions,
        },
      };

  String encode() => jsonEncode(toJson());

  EqReceipt copyWith({
    String? id,
    DateTime? issuedAt,
    String? currency,
    String? receiptType,
    String? merchantName,
    String? taxId,
    List<EqItem>? items,
    double? grandTotal,
    Map<String, dynamic>? extensions,
  }) {
    return EqReceipt(
      id: id ?? this.id,
      issuedAt: issuedAt ?? this.issuedAt,
      currency: currency ?? this.currency,
      receiptType: receiptType ?? this.receiptType,
      merchantName: merchantName ?? this.merchantName,
      taxId: taxId ?? this.taxId,
      items: items ?? this.items,
      grandTotal: grandTotal ?? this.grandTotal,
      extensions: extensions ?? this.extensions,
    );
  }
}

double _num(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
