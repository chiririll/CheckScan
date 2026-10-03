import 'package:receipt_model/receipt_model.dart';

import '../util/collections.dart';

const manualAdapterId = 'manual';

/// Manual entry is its own "provider": it sets the scale itself instead of deriving it from the currency.
const manualScale = 2;

/// Quantities are typed with up to three fraction digits ("1,235" kg).
const _qtyScale = 3;

enum ManualReceiptError { invalidItem, invalidTotal }

/// One line as typed: raw text, parsed only when the receipt is built.
class ManualItemDraft {
  ManualItemDraft({this.name = '', this.quantity = '', this.price = ''});

  String name;
  String quantity;
  String price;

  bool get isBlank => name.trim().isEmpty && quantity.trim().isEmpty && price.trim().isEmpty;

  /// Line sum in minor units; null while quantity or price is not a number. Empty quantity counts as 1.
  int? get sum {
    final price = parseMinor(this.price, manualScale);
    final qty = parseQuantity(quantity);
    if (price == null || qty == null) return null;
    return rescaleMinor(price * qty, manualScale + _qtyScale, manualScale);
  }
}

/// A receipt form's state.
class ManualReceiptDraft {
  ManualReceiptDraft({
    this.merchantName = '',
    DateTime? issuedAt,
    this.currency = 'RUB',
    List<ManualItemDraft>? items,
    this.totalText = '',
  })  : issuedAt = issuedAt ?? DateTime.now(),
        items = items ?? [];

  String merchantName;
  DateTime issuedAt;
  String currency;
  final List<ManualItemDraft> items;

  /// Used only while there are no items.
  String totalText;

  factory ManualReceiptDraft.fromReceipt(Receipt receipt) {
    return ManualReceiptDraft(
      merchantName: receipt.merchantName ?? '',
      issuedAt: receipt.issuedAt.toLocal(),
      currency: receipt.currency,
      totalText: receipt.items.isEmpty ? plainMinor(receipt.total, receipt.scale) : '',
      items: [
        for (final item in receipt.items)
          ManualItemDraft(
            name: item.name,
            quantity: plainMinor((item.quantity * 1000).round(), _qtyScale),
            price: plainMinor(item.price, receipt.scale),
          ),
      ],
    );
  }

  List<ManualItemDraft> get filledItems => items.where((item) => !item.isBlank).toList();

  /// Sum of the typed lines; null when any of them is not valid yet.
  int? get itemsTotal {
    var total = 0;
    for (final item in filledItems) {
      final sum = item.sum;
      if (sum == null) return null;
      total += sum;
    }
    return total;
  }

  /// Total as the form shows it: the lines' sum, or the typed amount without lines.
  int? get total => filledItems.isEmpty ? parseMinor(totalText, manualScale) : itemsTotal;
}

/// Builds the receipt to store, or says what is wrong with the form.
({Receipt? receipt, ManualReceiptError? error}) buildManualReceipt(ManualReceiptDraft draft, {required String id}) {
  final items = <ReceiptItem>[];
  for (final line in draft.filledItems) {
    final price = parseMinor(line.price, manualScale);
    final qty = parseQuantity(line.quantity);
    final sum = line.sum;
    if (line.name.trim().isEmpty || price == null || qty == null || sum == null) {
      return (receipt: null, error: ManualReceiptError.invalidItem);
    }
    items.add(ReceiptItem(name: line.name.trim(), quantity: qty / 1000, price: price, sum: sum));
  }
  final total = draft.total;
  if (total == null || total <= 0) return (receipt: null, error: ManualReceiptError.invalidTotal);
  return (
    receipt: Receipt(
      id: id,
      issuedAt: draft.issuedAt,
      currency: draft.currency,
      scale: manualScale,
      total: total,
      merchantName: trimmedOrNull(draft.merchantName),
      items: items,
    ),
    error: null,
  );
}

/// Quantity in thousandths. Empty means 1; zero and negatives are not quantities.
int? parseQuantity(String raw) {
  if (raw.trim().isEmpty) return 1000;
  final qty = parseMinor(raw, _qtyScale);
  return qty == null || qty <= 0 ? null : qty;
}

/// "89.25", "100", "1.235": [minor] with [exp] fraction digits, trailing zeros dropped.
String plainMinor(int minor, int exp) {
  final parts = splitMinor(minor, exp);
  final fraction = parts.fraction.replaceFirst(RegExp(r'0+$'), '');
  final sign = parts.negative ? '-' : '';
  return fraction.isEmpty ? '$sign${parts.whole}' : '$sign${parts.whole}.$fraction';
}
