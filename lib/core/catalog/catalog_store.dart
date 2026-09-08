import 'package:flutter/foundation.dart';

import '../merchant/merchant.dart';
import '../models/receipt_record.dart';
import 'assist_apply.dart';
import 'assist_cluster.dart';
import 'assist_draft.dart';
import 'catalog_category.dart';
import 'catalog_position.dart';
import 'catalog_product.dart';
import 'catalog_repository.dart';
import 'catalog_resolver.dart';
import 'item_unit.dart';
import 'name_stem.dart';
import 'product_kind.dart';
import 'purchase.dart';

class CatalogStore extends ChangeNotifier {
  CatalogStore({required this._repository});

  final CatalogRepository _repository;

  CatalogResolver resolver = CatalogResolver.empty;
  List<CatalogCategory> categories = const [];
  List<CatalogProduct> products = const [];
  List<CatalogPosition> positions = const [];
  List<Merchant> merchants = const [];
  List<Purchase> purchases = const [];
  List<ReceiptRecord> _receipts = const [];

  List<CatalogPosition> get unassigned => [for (final position in positions) if (position.productId == null) position];

  List<CatalogCategory> get topCategories => [for (final category in categories) if (category.isTop) category];

  List<UnassignedCluster>? _unassignedClusters;
  Map<String, int>? _positionCounts;
  int? _countsStamp;

  List<UnassignedCluster> get unassignedClusters {
    return _unassignedClusters ??= buildUnassignedClusters(unassigned);
  }

  int? _pendingTab;

  void requestTab(int index) {
    _pendingTab = index;
    notifyListeners();
  }

  int? takePendingTab() {
    final index = _pendingTab;
    _pendingTab = null;
    return index;
  }

  Future<void> ingest(List<ReceiptRecord> receipts, {Iterable<Merchant> merchants = const []}) async {
    _receipts = List.of(receipts);
    this.merchants = merchants.toList();
    await _repository.ingestFromReceipts(_receipts, this.merchants);
    await reload();
    await _rebuildPurchases();
  }

  Future<void> syncPurchases(List<ReceiptRecord> receipts, {Iterable<Merchant> merchants = const []}) async {
    _receipts = List.of(receipts);
    if (merchants.isNotEmpty) this.merchants = merchants.toList();
    await _rebuildPurchases();
    notifyListeners();
  }

  Future<void> reload() async {
    categories = await _repository.listCategories();
    products = await _repository.listProducts();
    positions = await _repository.listPositions();
    resolver = await _repository.buildResolver();
    _unassignedClusters = null;
    _positionCounts = null;
    _countsStamp = null;
    notifyListeners();
  }

  Future<void> _rebuildPurchases() async {
    await _repository.rebuildPurchases(receipts: _receipts, merchants: this.merchants);
    purchases = await _repository.listPurchases();
  }

  Future<void> _afterCatalogChange() async {
    await reload();
    await _rebuildPurchases();
  }

  List<CatalogCategory> childrenOf(String categoryId) {
    return [for (final category in categories) if (category.parentId == categoryId) category];
  }

  bool hasChildren(String categoryId) => childrenOf(categoryId).isNotEmpty;

  List<CatalogCategory> assignableCategories() {
    return [for (final category in categories) if (!hasChildren(category.id)) category];
  }

  List<CatalogCategory> topCategoriesOnly() => topCategories;

  List<CatalogPosition> suggestionsFor(CatalogPosition position) {
    for (final cluster in unassignedClusters) {
      if (cluster.positions.length < 2) continue;
      if (!cluster.positions.any((item) => item.id == position.id)) continue;
      return [for (final item in cluster.positions) if (item.id != position.id) item];
    }
    return const [];
  }

  List<CatalogPosition> searchAttachableItems(String productId, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return [
      for (final item in positions)
        if (item.productId != productId && item.displayName.toLowerCase().contains(needle)) item,
    ];
  }

  List<CatalogPosition> similarCandidatesFor(String productId) {
    final product = productById(productId);
    if (product == null) return const [];
    final stem = itemNameStem(product.name);
    if (stem.isEmpty) return const [];
    return [
      for (final cluster in unassignedClusters)
        if (stemsSimilar(itemNameStem(cluster.name), stem)) ...cluster.positions,
    ];
  }

  Future<CatalogProduct> createProductWithPositions({
    required String name,
    String? categoryId,
    ItemUnit? unit,
    ProductKind kind = ProductKind.good,
    required List<String> positionIds,
  }) async {
    final product = await _repository.createProduct(name: name, categoryId: categoryId, unit: unit, kind: kind);
    for (final positionId in positionIds) {
      await _repository.assignPosition(positionId, product.id);
    }
    await _afterCatalogChange();
    return products.firstWhere((item) => item.id == product.id, orElse: () => product);
  }

  Future<void> mergePositions({required String sourceId, required String targetId}) async {
    await _repository.mergePositions(sourceId: sourceId, targetId: targetId);
    await _afterCatalogChange();
  }

  Future<void> mergeGroup({required String targetId, required List<String> sourceIds}) async {
    for (final sourceId in sourceIds) {
      if (sourceId == targetId) continue;
      await _repository.mergePositions(sourceId: sourceId, targetId: targetId);
    }
    await _afterCatalogChange();
  }

  Future<void> unalias(String rawName) async {
    await _repository.unalias(rawName);
    await _afterCatalogChange();
  }

  Future<CatalogProduct> createProduct({
    required String name,
    String? categoryId,
    String? positionId,
    ItemUnit? unit,
    ProductKind kind = ProductKind.good,
  }) async {
    final product = await _repository.createProduct(name: name, categoryId: categoryId, unit: unit, kind: kind);
    if (positionId != null) {
      await _repository.assignPosition(positionId, product.id);
    }
    await _afterCatalogChange();
    return products.firstWhere((item) => item.id == product.id, orElse: () => product);
  }

  Future<void> assignPosition(String positionId, String? productId) async {
    await _repository.assignPosition(positionId, productId);
    await _afterCatalogChange();
  }

  Future<void> updateProduct(
    String id, {
    String? name,
    String? categoryId,
    bool clearCategory = false,
    ItemUnit? unit,
    bool clearUnit = false,
    ProductKind? kind,
  }) async {
    await _repository.updateProduct(
      id,
      name: name,
      categoryId: categoryId,
      clearCategory: clearCategory,
      unit: unit,
      clearUnit: clearUnit,
      kind: kind,
    );
    await reload();
  }

  Future<void> deleteProduct(String id) async {
    await _repository.deleteProduct(id);
    await _afterCatalogChange();
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

  Future<void> addItemTag(String itemId, String name) async {
    if (name.trim().isEmpty) return;
    await _repository.addItemTag(itemId, name);
    await reload();
  }

  Future<void> removeItemTag(String itemId, String tagId) async {
    await _repository.removeItemTag(itemId, tagId);
    await reload();
  }

  Future<void> updatePosition(String id, {double? unitSize, bool clearAmount = false}) async {
    await _repository.updatePosition(id, unitSize: unitSize, clearAmount: clearAmount);
    await reload();
  }

  Future<void> applyAssistDraft(AssistDraft draft) async {
    await applyAssistDraftToRepo(repository: _repository, draft: draft, products: products);
    await _afterCatalogChange();
  }

  Future<void> createCategory(String name, {String? parentId}) async {
    if (name.trim().isEmpty) return;
    await _repository.createCategory(name, parentId: parentId);
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
    var items = 0;
    for (final receipt in receipts) {
      items += receipt.receipt.items.length;
    }
    final stamp = Object.hash(receipts.length, items);
    if (_positionCounts != null && _countsStamp == stamp) return _positionCounts!;
    final counts = <String, int>{};
    for (final receipt in receipts) {
      for (final item in receipt.receipt.items) {
        final hit = resolver.resolve(item.description);
        final key = hit?.position.id ?? item.description;
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    _countsStamp = stamp;
    _positionCounts = counts;
    return counts;
  }
}
