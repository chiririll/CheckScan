import '../catalog/catalog_category.dart';
import '../catalog/catalog_resolver.dart';
import '../catalog/category_top.dart';
import '../merchant/merchant.dart';
import '../models/receipt_record.dart';

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
  final merchantById = {for (final merchant in merchants) merchant.id: merchant};
  final rows = <CategoryExportRow>[];

  for (final receipt in receipts) {
    final merchant = receipt.merchantId == null ? null : merchantById[receipt.merchantId!];
    final merchantName = merchant?.name ?? receipt.merchantName ?? '';
    final at = receipt.issuedAt ?? receipt.scannedAt;

    if (merchant != null && merchant.ignoresItems) {
      final top = topCategoryOf(categoryId: merchant.categoryId, byId: byId);
      rows.add(
        CategoryExportRow(
          at: at,
          merchant: merchantName,
          receiptId: receipt.id,
          categoryKey: top?.name ?? '',
          amount: receipt.grandTotal,
          currency: receipt.currency,
        ),
      );
      continue;
    }

    final buckets = <String, _Bucket>{};
    for (final line in receipt.receipt.items) {
      final hit = resolver.resolve(line.description);
      final top = topCategoryOf(categoryId: hit?.product?.categoryId ?? hit?.category?.id, byId: byId);
      final key = top?.name ?? '';
      final bucket = buckets.putIfAbsent(key, _Bucket.new);
      bucket.amount += line.totalPrice;
      final label = hit?.product?.name ?? line.description;
      if (label.isNotEmpty) {
        bucket.items.add('$label × ${_qty(line.quantity)}');
      }
    }

    if (buckets.isEmpty) {
      rows.add(
        CategoryExportRow(
          at: at,
          merchant: merchantName,
          receiptId: receipt.id,
          categoryKey: '',
          amount: receipt.grandTotal,
          currency: receipt.currency,
        ),
      );
      continue;
    }

    for (final entry in buckets.entries) {
      rows.add(
        CategoryExportRow(
          at: at,
          merchant: merchantName,
          receiptId: receipt.id,
          categoryKey: entry.key,
          amount: entry.value.amount,
          currency: receipt.currency,
          items: entry.value.items,
        ),
      );
    }
  }

  rows.sort((a, b) {
    final byDate = b.at.compareTo(a.at);
    if (byDate != 0) return byDate;
    return a.categoryKey.compareTo(b.categoryKey);
  });
  return rows;
}

String categoryCsvFileName([DateTime? now]) {
  final date = now ?? DateTime.now();
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return 'checkscan-categories-$year-$month-$day.csv';
}

String encodeCategoryCsv(
  Iterable<CategoryExportRow> rows, {
  String Function(String key)? categoryName,
}) {
  final nameOf = categoryName ?? (key) => key;
  final buffer = StringBuffer('date,merchant,category_key,category,amount,currency,items\n');
  for (final row in rows) {
    final date = '${row.at.year.toString().padLeft(4, '0')}-${row.at.month.toString().padLeft(2, '0')}-${row.at.day.toString().padLeft(2, '0')}';
    buffer
      ..write(_cell(date))
      ..write(',')
      ..write(_cell(row.merchant))
      ..write(',')
      ..write(_cell(row.categoryKey))
      ..write(',')
      ..write(_cell(nameOf(row.categoryKey)))
      ..write(',')
      ..write(_cell(row.amount.toStringAsFixed(2)))
      ..write(',')
      ..write(_cell(row.currency))
      ..write(',')
      ..write(_cell(row.items.join('; ')))
      ..write('\n');
  }
  return buffer.toString();
}

class _Bucket {
  double amount = 0;
  final List<String> items = [];
}

String _qty(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}

String _cell(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
