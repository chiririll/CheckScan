import 'package:flutter/foundation.dart';

import '../util/collections.dart';
import 'merchant.dart';
import 'merchant_repository.dart';

/// Loaded merchants plus edits that refresh the list.
class MerchantStore extends ChangeNotifier {
  MerchantStore({required this._repository});

  final MerchantRepository _repository;

  List<Merchant> all = const [];

  Merchant? byId(String? id) => id == null ? null : all.firstWhereOrNull((merchant) => merchant.id == id);

  Future<void> reload() async {
    all = await _repository.listAll();
    notifyListeners();
  }

  Future<void> update(
    String id, {
    String? name,
    String? parentId,
    bool clearParent = false,
    String? policy,
    String? categoryId,
    bool clearCategory = false,
  }) async {
    await _repository.update(
      id,
      name: name,
      parentId: parentId,
      clearParent: clearParent,
      policy: policy,
      categoryId: categoryId,
      clearCategory: clearCategory,
    );
    await reload();
  }

  Future<void> addAlias(String merchantId, {String? name, String? taxId}) async {
    await _repository.addAlias(merchantId, name: name, taxId: taxId);
    await reload();
  }
}
