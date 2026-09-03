import 'dart:convert';

import 'catalog_category.dart';
import 'catalog_position.dart';
import 'catalog_product.dart';
import 'assist_draft.dart';
import 'item_unit.dart';
import 'name_normalizer.dart';

class AssistParseContext {
  const AssistParseContext({
    required this.categories,
    required this.products,
    required this.positions,
    required this.seedLabels,
  });

  final List<CatalogCategory> categories;
  final List<CatalogProduct> products;
  final List<CatalogPosition> positions;
  final Map<String, String> seedLabels;
}

AssistParseResult parseAssistJson(String raw, AssistParseContext context) {
  final extracted = extractJsonObject(raw);
  if (extracted == null) {
    return raw.trim().isEmpty ? const AssistParseResult.fail(AssistParseError.empty) : const AssistParseResult.fail(AssistParseError.notJson);
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(extracted);
  } on FormatException {
    return const AssistParseResult.fail(AssistParseError.notJson);
  }
  if (decoded is! Map) return const AssistParseResult.fail(AssistParseError.notJson);
  if (!decoded.containsKey('products') || decoded['products'] is! List) {
    return const AssistParseResult.fail(AssistParseError.noProducts);
  }

  final allowedIds = {for (final position in context.positions) if (position.productId == null) position.id};
  final productIds = {for (final product in context.products) product.id};
  final newCategories = <String, AssistNewCategory>{};
  var skipped = 0;

  void rememberNew(String name) {
    final key = tagNameKey(name);
    if (key.isEmpty || newCategories.containsKey(key)) return;
    newCategories[key] = AssistNewCategory(key: key, name: name.trim());
  }

  final listed = decoded['categories'];
  if (listed is List) {
    for (final item in listed) {
      if (item is! Map) {
        skipped += 1;
        continue;
      }
      final name = '${item['name'] ?? ''}'.trim();
      if (name.isEmpty) {
        skipped += 1;
        continue;
      }
      final hit = resolveAssistCategory(name, context);
      if (hit == null) rememberNew(name);
    }
  }

  final products = <AssistDraftProduct>[];
  for (final item in decoded['products'] as List) {
    if (item is! Map) {
      skipped += 1;
      continue;
    }
    final name = '${item['name'] ?? ''}'.trim();
    if (name.isEmpty) {
      skipped += 1;
      continue;
    }
    final existingId = item['existingProductId']?.toString();
    final existingProductId = existingId != null && existingId.isNotEmpty && existingId != 'null' && productIds.contains(existingId)
        ? existingId
        : null;
    String? existingCategoryId;
    String? newCategoryKey;
    final categoryRaw = item['category']?.toString().trim();
    if (categoryRaw != null && categoryRaw.isNotEmpty && categoryRaw != 'null') {
      final hit = resolveAssistCategory(categoryRaw, context);
      if (hit != null) {
        existingCategoryId = hit;
      } else {
        rememberNew(categoryRaw);
        newCategoryKey = tagNameKey(categoryRaw);
      }
    }
    final unit = ItemUnit.tryParse(item['unit']?.toString());
    final positions = <AssistDraftPosition>[];
    final rawPositions = item['positions'];
    if (rawPositions is List) {
      for (final row in rawPositions) {
        if (row is! Map) {
          skipped += 1;
          continue;
        }
        final id = '${row['id'] ?? ''}';
        if (!allowedIds.contains(id)) {
          skipped += 1;
          continue;
        }
        final brand = '${row['brand'] ?? ''}'.trim();
        positions.add(
          AssistDraftPosition(
            id: id,
            unitSize: _readSize(row['unitSize']),
            brand: brand.isEmpty ? null : brand,
          ),
        );
      }
    }
    if (existingProductId == null && positions.isEmpty) {
      skipped += 1;
      continue;
    }
    products.add(
      AssistDraftProduct(
        name: name,
        existingProductId: existingProductId,
        existingCategoryId: existingCategoryId,
        newCategoryKey: newCategoryKey,
        unit: unit,
        positions: positions,
      ),
    );
  }

  final draft = AssistDraft(newCategories: newCategories.values.toList(), products: products, skippedCount: skipped);
  if (draft.isEmpty) return const AssistParseResult.fail(AssistParseError.nothingToApply);
  return AssistParseResult.ok(draft);
}

String? extractJsonObject(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return null;
  text = text.replaceFirst(RegExp(r'^```(?:json)?', caseSensitive: false), '');
  text = text.replaceFirst(RegExp(r'```\s*$'), '');
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  return text.substring(start, end + 1);
}

String? resolveAssistCategory(String raw, AssistParseContext context) {
  final needle = raw.trim();
  if (needle.isEmpty) return null;
  for (final category in context.categories) {
    if (category.id == needle || category.name == needle) return category.id;
  }
  final folded = tagNameKey(needle);
  for (final entry in context.seedLabels.entries) {
    if (tagNameKey(entry.value) == folded) {
      for (final category in context.categories) {
        if (category.name == entry.key) return category.id;
      }
    }
  }
  for (final category in context.categories) {
    if (tagNameKey(category.name) == folded) return category.id;
  }
  return null;
}

double? _readSize(Object? raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw.replaceAll(',', '.'));
  return null;
}
