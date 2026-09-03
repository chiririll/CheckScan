import 'item_unit.dart';

enum AssistParseError { empty, notJson, noProducts, nothingToApply }

class AssistNewCategory {
  const AssistNewCategory({required this.key, required this.name});

  final String key;
  final String name;
}

class AssistDraftPosition {
  const AssistDraftPosition({required this.id, this.unitSize, this.brand});

  final String id;
  final double? unitSize;
  final String? brand;
}

class AssistDraftProduct {
  const AssistDraftProduct({
    required this.name,
    this.existingProductId,
    this.existingCategoryId,
    this.newCategoryKey,
    this.unit,
    this.positions = const [],
  });

  final String name;
  final String? existingProductId;
  final String? existingCategoryId;
  final String? newCategoryKey;
  final ItemUnit? unit;
  final List<AssistDraftPosition> positions;

  AssistDraftProduct copyWith({
    String? existingCategoryId,
    String? newCategoryKey,
    bool clearCategory = false,
    List<AssistDraftPosition>? positions,
  }) {
    return AssistDraftProduct(
      name: name,
      existingProductId: existingProductId,
      existingCategoryId: clearCategory ? null : (existingCategoryId ?? this.existingCategoryId),
      newCategoryKey: clearCategory ? null : (newCategoryKey ?? this.newCategoryKey),
      unit: unit,
      positions: positions ?? this.positions,
    );
  }
}

class AssistDraft {
  const AssistDraft({this.newCategories = const [], this.products = const [], this.skippedCount = 0});

  final List<AssistNewCategory> newCategories;
  final List<AssistDraftProduct> products;
  final int skippedCount;

  bool get isEmpty => newCategories.isEmpty && products.isEmpty;

  AssistDraft withoutCategory(String key) {
    return AssistDraft(
      newCategories: [for (final category in newCategories) if (category.key != key) category],
      products: [
        for (final product in products)
          product.newCategoryKey == key ? product.copyWith(clearCategory: true) : product,
      ],
      skippedCount: skippedCount,
    );
  }

  AssistDraft withoutProduct(int index) {
    return AssistDraft(
      newCategories: newCategories,
      products: [for (var i = 0; i < products.length; i++) if (i != index) products[i]],
      skippedCount: skippedCount,
    );
  }

  AssistDraft withoutPosition(int productIndex, String positionId) {
    return AssistDraft(
      newCategories: newCategories,
      products: [
        for (var i = 0; i < products.length; i++)
          if (i == productIndex)
            products[i].copyWith(
              positions: [for (final position in products[i].positions) if (position.id != positionId) position],
            )
          else
            products[i],
      ],
      skippedCount: skippedCount,
    );
  }
}

class AssistParseResult {
  const AssistParseResult.ok(this.draft) : error = null;
  const AssistParseResult.fail(this.error) : draft = null;

  final AssistDraft? draft;
  final AssistParseError? error;

  bool get isOk => draft != null && error == null;
}
