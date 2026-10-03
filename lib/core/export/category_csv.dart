import '../catalog/catalog_resolver.dart';
import '../catalog/category_top.dart';
import '../catalog/model/catalog_category.dart';
import '../format/format.dart';
import '../merchant/merchant.dart';
import '../models/receipt_record.dart';
import '../util/collections.dart';
import 'export_file.dart';

class CategoryExportRow {
  const CategoryExportRow({
    required this.at,
    required this.merchant,
    required this.receiptId,
    required this.categoryKey,
    required this.amount,
    required this.currency,
    this.items = const [],
  });

  final DateTime at;
  final String merchant;
  final String receiptId;
  final String categoryKey;
  final double amount;
  final String currency;
  final List<String> items;
}

/// One row per receipt and top-level shelf. Mixed tops split; ignore merchants stay one sum.
List<CategoryExportRow> buildCategoryExport({
  required List<ReceiptRecord> receipts,
  required CatalogResolver resolver,
  required List<CatalogCategory> categories,
  required List<Merchant> merchants,
}) {
  final byId = categoryIndex(categories);
  final merchantById = merchants.indexBy((merchant) => merchant.id);
  final rows = <CategoryExportRow>[];

  for (final receipt in receipts) {
    final merchant = merchantById[receipt.merchantId];

    CategoryExportRow row(String categoryKey, double amount, [List<String> items = const []]) {
      return CategoryExportRow(
        at: receipt.at,
        merchant: merchant?.name ?? receipt.merchantName ?? '',
        receiptId: receipt.id,
        categoryKey: categoryKey,
        amount: amount,
        currency: receipt.currency,
        items: items,
      );
    }

    if (merchant != null && merchant.ignoresItems) {
      final top = topCategoryOf(categoryId: merchant.categoryId, byId: byId);
      rows.add(row(top?.name ?? '', receipt.grandTotal));
      continue;
    }

    final buckets = _bucketsByTop(receipt, resolver, byId);
    if (buckets.isEmpty) {
      rows.add(row('', receipt.grandTotal));
      continue;
    }
    for (final MapEntry(key: categoryKey, value: bucket) in buckets.entries) {
      rows.add(row(categoryKey, bucket.amount, bucket.items));
    }
  }

  rows.sort((a, b) {
    final byDate = b.at.compareTo(a.at);
    if (byDate != 0) return byDate;
    return a.categoryKey.compareTo(b.categoryKey);
  });
  return rows;
}

Map<String, _Bucket> _bucketsByTop(
  ReceiptRecord receipt,
  CatalogResolver resolver,
  Map<String, CatalogCategory> byId,
) {
  final buckets = <String, _Bucket>{};
  for (final line in receipt.receipt.items) {
    final hit = resolver.resolve(line.description);
    final top = topCategoryOf(categoryId: hit?.product?.categoryId ?? hit?.category?.id, byId: byId);
    final bucket = buckets.putIfAbsent(top?.name ?? '', _Bucket.new);
    bucket.amount += line.totalPrice;
    final label = hit?.product?.name ?? line.description;
    if (label.isNotEmpty) bucket.items.add('$label × ${formatQty(line.quantity)}');
  }
  return buckets;
}

String categoryCsvFileName([DateTime? now]) => datedExportName('categories', 'csv', now);

String encodeCategoryCsv(
  Iterable<CategoryExportRow> rows, {
  String Function(String key)? categoryName,
}) {
  final nameOf = categoryName ?? (key) => key;
  final buffer = StringBuffer('date,merchant,category_key,category,amount,currency,items\n');
  for (final row in rows) {
    final cells = [
      isoDate(row.at),
      row.merchant,
      row.categoryKey,
      nameOf(row.categoryKey),
      row.amount.toStringAsFixed(2),
      row.currency,
      row.items.join('; '),
    ];
    buffer.writeln(cells.map(_cell).join(','));
  }
  return buffer.toString();
}

class _Bucket {
  double amount = 0;
  final List<String> items = [];
}

String _cell(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
