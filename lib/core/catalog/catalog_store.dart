import 'package:flutter/foundation.dart';

import '../merchant/merchant.dart';
import '../models/receipt_record.dart';
import '../util/collections.dart';
import 'assist/assist_apply.dart';
import 'assist/assist_cluster.dart';
import 'assist/assist_draft.dart';
import 'catalog_resolver.dart';
import 'data/catalog_repository.dart';
import 'model/catalog_category.dart';
import 'model/catalog_position.dart';
import 'model/catalog_product.dart';
import 'model/item_unit.dart';
import 'model/product_kind.dart';
import 'model/purchase.dart';
import 'model/suggestion_ignore.dart';
import 'text/name_stem.dart';

/// In-memory catalog snapshot plus the mutations that keep it in sync with the DB.
class CatalogStore extends ChangeNotifier {
  CatalogStore({required this._repository});

  final CatalogRepository _repository;

  CatalogResolver resolver = CatalogResolver.empty;
  List<CatalogCategory> categories = const [];
  List<CatalogProduct> products = const [];
  List<CatalogPosition> positions = const [];
  List<Purchase> purchases = const [];
  SuggestionIgnore suggestionIgnore = const SuggestionIgnore();

  /// Receipts and merchants that purchases are derived from. Null until [ingest].
  List<ReceiptRecord>? _receipts;
  List<Merchant> _merchants = const [];
  List<UnassignedCluster>? _unassignedClusters;

  // Queries.

  List<CatalogPosition> get unassigned => [for (final position in positions) if (position.productId == null) position];

  List<CatalogCategory> get topCategories => [for (final category in categories) if (category.isTop) category];

  List<UnassignedCluster> get unassignedClusters {
    return _unassignedClusters ??= buildUnassignedClusters(unassigned, ignoreIds: suggestionIgnore.clusterItemIds);
  }

  List<CatalogCategory> childrenOf(String categoryId) {
    return [for (final category in categories) if (category.parentId == categoryId) category];
  }

  bool hasChildren(String categoryId) => categories.any((category) => category.parentId == categoryId);

  CatalogProduct? productById(String id) => products.firstWhereOrNull((product) => product.id == id);

  CatalogCategory? categoryById(String id) => categories.firstWhereOrNull((category) => category.id == id);

  CatalogPosition? positionById(String id) => positions.firstWhereOrNull((position) => position.id == id);

  List<CatalogPosition> positionsOf(String productId) {
    return [for (final position in positions) if (position.productId == productId) position];
  }

  List<CatalogPosition> searchAttachableItems(String productId, String query) {
    if (query.trim().isEmpty) return const [];
    return filterByQuery(
      positions.where((item) => item.productId != productId),
      query,
      (item) => [item.displayName],
    );
  }

  /// Unassigned positions whose name stem resembles the product name.
  List<CatalogPosition> similarCandidatesFor(String productId) {
    final product = productById(productId);
    if (product == null) return const [];
    final stem = itemNameStem(product.name);
    if (stem.isEmpty) return const [];
    return [
      for (final cluster in unassignedClusters)
        if (stemsSimilar(itemNameStem(cluster.name), stem))
          for (final item in cluster.positions)
            if (!suggestionIgnore.ignoresProduct(productId, item.id)) item,
    ];
  }

  // Loading.

  /// Binds receipts, creates positions for new names, and rebuilds purchases.
  Future<void> ingest(List<ReceiptRecord> receipts, {Iterable<Merchant> merchants = const []}) async {
    _receipts = List.of(receipts);
    _merchants = merchants.toList();
    await _repository.ingestFromReceipts(receipts, _merchants);
    await reload();
    await _rebuildPurchases();
  }

  Future<void> syncPurchases(List<ReceiptRecord> receipts, {Iterable<Merchant> merchants = const []}) async {
    if (_receipts != null) _receipts = List.of(receipts);
    if (merchants.isNotEmpty) _merchants = merchants.toList();
    await _rebuildPurchases();
    notifyListeners();
  }

  Future<void> reload() async {
    categories = await _repository.listCategories();
    products = await _repository.listProducts();
    positions = await _repository.listPositions();
    suggestionIgnore = await _repository.listSuggestionIgnores();
    resolver = CatalogResolver.from(categories: categories, products: products, positions: positions);
    _unassignedClusters = null;
    notifyListeners();
  }

  Future<void> _rebuildPurchases() async {
    final receipts = _receipts;
    if (receipts == null) {
      purchases = const [];
      return;
    }
    await _repository.rebuildPurchases(receipts: receipts, merchants: _merchants, resolver: resolver);
    purchases = await _repository.listPurchases();
  }

  /// Runs a write, then refreshes the snapshot. Writes that change which product
  /// a line resolves to also rebuild purchases.
  Future<T> _write<T>(Future<T> Function() write, {bool affectsPurchases = false}) async {
    final result = await write();
    await reload();
    if (affectsPurchases) await _rebuildPurchases();
    return result;
  }

  // Products and positions.

  Future<CatalogProduct> createProduct({
    required String name,
    String? categoryId,
    String? positionId,
    ItemUnit? unit,
    ProductKind kind = ProductKind.good,
  }) {
    return createProductWithPositions(
      name: name,
      categoryId: categoryId,
      unit: unit,
      kind: kind,
      positionIds: [?positionId],
    );
  }

  Future<CatalogProduct> createProductWithPositions({
    required String name,
    String? categoryId,
    ItemUnit? unit,
    ProductKind kind = ProductKind.good,
    required List<String> positionIds,
  }) async {
    final created = await _write(affectsPurchases: true, () async {
      final product = await _repository.createProduct(name: name, categoryId: categoryId, unit: unit, kind: kind);
      for (final positionId in positionIds) {
        await _repository.assignPosition(positionId, product.id);
      }
      return product;
    });
    return productById(created.id) ?? created;
  }

  Future<void> updateProduct(
    String id, {
    String? name,
    String? categoryId,
    bool clearCategory = false,
    ItemUnit? unit,
    bool clearUnit = false,
    ProductKind? kind,
  }) {
    return _write(() => _repository.updateProduct(
          id,
          name: name,
          categoryId: categoryId,
          clearCategory: clearCategory,
          unit: unit,
          clearUnit: clearUnit,
          kind: kind,
        ));
  }

  Future<void> deleteProduct(String id) => _write(() => _repository.deleteProduct(id), affectsPurchases: true);

  Future<void> assignPosition(String positionId, String? productId) {
    return _write(() => _repository.assignPosition(positionId, productId), affectsPurchases: true);
  }

  Future<void> updatePosition(String id, {double? unitSize, bool clearAmount = false}) {
    return _write(() => _repository.updatePosition(id, unitSize: unitSize, clearAmount: clearAmount));
  }

  Future<void> unalias(String rawName) => _write(() => _repository.unalias(rawName), affectsPurchases: true);

  Future<void> applyAssistDraft(AssistDraft draft) {
    return _write(() => applyAssistDraftToRepo(repository: _repository, draft: draft), affectsPurchases: true);
  }

  // Tags.

  Future<void> addTag(String productId, String name) async {
    if (name.trim().isEmpty) return;
    await _write(() => _repository.addProductTag(productId, name));
  }

  Future<void> removeTag(String productId, String tagId) => _write(() => _repository.removeProductTag(productId, tagId));

  Future<void> addItemTag(String itemId, String name) async {
    if (name.trim().isEmpty) return;
    await _write(() => _repository.addItemTag(itemId, name));
  }

  Future<void> removeItemTag(String itemId, String tagId) => _write(() => _repository.removeItemTag(itemId, tagId));

  // Suggestions.

  Future<void> dismissClusterItem(String itemId) => _write(() => _repository.ignoreClusterItem(itemId));

  Future<void> dismissCluster(Iterable<String> itemIds) => _write(() => _repository.ignoreClusterItems(itemIds));

  Future<void> dismissProductSuggestion({required String productId, required String itemId}) {
    return _write(() => _repository.ignoreProductSuggestion(productId: productId, itemId: itemId));
  }

  // Categories.

  Future<void> createCategory(String name, {String? parentId}) async {
    if (name.trim().isEmpty) return;
    await _write(() => _repository.createCategory(name, parentId: parentId));
  }

  Future<void> renameCategory(String id, String name) => _write(() => _repository.renameCategory(id, name));

  Future<void> deleteCategory(String id) => _write(() => _repository.deleteCategory(id));
}
