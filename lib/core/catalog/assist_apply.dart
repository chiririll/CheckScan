import 'assist_draft.dart';
import 'catalog_product.dart';
import 'catalog_repository.dart';

Future<void> applyAssistDraftToRepo({
  required CatalogRepository repository,
  required AssistDraft draft,
  required List<CatalogProduct> products,
}) async {
  final createdCategoryIds = <String, String>{};
  for (final category in draft.newCategories) {
    final created = await repository.createCategory(category.name);
    createdCategoryIds[category.key] = created.id;
  }

  String? categoryIdOf(AssistDraftProduct product) {
    return product.existingCategoryId ?? createdCategoryIds[product.newCategoryKey];
  }

  CatalogProduct? productById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  for (final item in draft.products) {
    final categoryId = categoryIdOf(item);
    if (item.existingProductId != null) {
      final current = productById(item.existingProductId!);
      if (current == null) continue;
      await repository.updateProduct(
        current.id,
        categoryId: current.categoryId == null ? categoryId : null,
        unit: current.unit == null ? item.unit : null,
      );
      for (final position in item.positions) {
        await repository.assignPosition(position.id, current.id);
        if (position.unitSize != null) {
          await repository.updatePosition(position.id, unitSize: position.unitSize);
        }
      }
      continue;
    }
    final created = await repository.createProduct(name: item.name, categoryId: categoryId, unit: item.unit);
    for (final position in item.positions) {
      await repository.assignPosition(position.id, created.id);
      if (position.unitSize != null) {
        await repository.updatePosition(position.id, unitSize: position.unitSize);
      }
    }
  }
}
