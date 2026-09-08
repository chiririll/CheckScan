class Purchase {
  const Purchase({
    required this.id,
    required this.checkId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.currency,
    this.issuedAt,
    this.scannedAt,
    this.merchantId,
    this.merchantName,
  });

  final String id;
  final String checkId;
  final String productId;
  final double quantity;
  final double unitPrice;
  final double total;
  final String currency;
  final DateTime? issuedAt;
  final DateTime? scannedAt;
  final String? merchantId;
  final String? merchantName;

  DateTime get at => issuedAt ?? scannedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
}
