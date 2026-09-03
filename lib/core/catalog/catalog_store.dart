import 'package:flutter/foundation.dart';

import '../models/receipt_record.dart';
import 'catalog_category.dart';
import 'catalog_position.dart';
import 'catalog_product.dart';
import 'catalog_repository.dart';
import 'catalog_resolver.dart';
import 'item_unit.dart';
import 'position_suggestions.dart';

class CatalogStore extends ChangeNotifier {
  CatalogStore({required this._repository});

  final CatalogRepository _repository;

  CatalogResolver resolver = CatalogResolver.empty;
  List<CatalogCategory> categories = const [];
  List<CatalogProduct> products = const [];
  List<CatalogPosition> positions = const [];

  List<CatalogPosition> get unassigned => [for (final position in positions) if (position.productId == null) position];

  Future<void> ingest(List<ReceiptRecord> receipts) async {
    final names = <String>{};
    for (final receipt in receipts) {
      for (final item in receipt.receipt.items) {
        if (item.description.isNotEmpty) names.add(item.description);
      }
    }
    await _repository.ingest(names);
    await reload();
  }

  Future<void> reload() async {
    categories = await _repository.listCategories();
    products = await _repository.listProducts();
    positions = await _repository.listPositions();
    resolver = await _repository.buildResolver();
    notifyListeners();
  }

  List<CatalogPosition> suggestionsFor(CatalogPosition position) {
    return suggestPositionMerges(position.displayName, positions: positions, excludeId: position.id);
  }

  Future<void> mergePositions({required String sourceId, required String targetId}) async {
    await _repository.mergePositions(sourceId: sourceId, targetId: targetId);
    await reload();
  }

  Future<void> unalias(String rawName) async {
    await _repository.unalias(rawName);
    await reload();
  }

  Future<CatalogProduct> createProduct({
    required String name,
    String? categoryId,
    String? positionId,
  }) async {
    final product = await _repository.createProduct(name: name, categoryId: categoryId);
    if (positionId != null) {
      await _repository.assignPosition(positionId, product.id);
    }
    await reload();
    return products.firstWhere((item) => item.id == product.id, orElse: () => product);
  }

  Future<void> assignPosition(String positionId, String? productId) async {
    await _repository.assignPosition(positionId, productId);
    await reload();
  }

  Future<void> updateProduct(String id, {String? name, String? categoryId, bool clearCategory = false}) async {
    await _repository.updateProduct(id, name: name, categoryId: categoryId, clearCategory: clearCategory);
    await reload();
  }

  Future<void> deleteProduct(String id) async {
    await _repository.deleteProduct(id);
    await reload();
  }

  Future<void> addTag(String productId, String name) async {
    if (name.trim().isEmpty) return;
    await _repository.addProductTag(productId, name);
    await reload();
  }

  Future<void> removeTag(String productId, String tagId) async {
    await _repository.removeProductTag(productId, tagId);
    await reload();
  }

  Future<void> updatePosition(String id, {ItemUnit? unit, double? unitSize, bool clearUnit = false}) async {
    await _repository.updatePosition(id, unit: unit, unitSize: unitSize, clearUnit: clearUnit);
    await reload();
  }

  Future<void> createCategory(String name) async {
    if (name.trim().isEmpty) return;
    await _repository.createCategory(name);
    await reload();
  }

  Future<void> renameCategory(String id, String name) async {
    await _repository.renameCategory(id, name);
    await reload();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    await reload();
  }

  CatalogProduct? productById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  CatalogCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  CatalogPosition? positionById(String id) {
    for (final position in positions) {
      if (position.id == id) return position;
    }
    return null;
  }

  Map<String, int> positionCounts(List<ReceiptRecord> receipts) {
    final counts = <String, int>{};
    for (final receipt in receipts) {
      for (final item in receipt.receipt.items) {
        final hit = resolver.resolve(item.description);
        final key = hit?.position.id ?? item.description;
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    return counts;
  }
}
