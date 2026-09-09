import 'assist_draft.dart';
import 'catalog_repository.dart';

Future<void> applyAssistDraftToRepo({
  required CatalogRepository repository,
  required AssistDraft draft,
}) async {
  for (final item in draft.products) {
    if (item.positions.isEmpty) continue;
    final created = await repository.createProduct(name: item.name);
    for (final position in item.positions) {
      await repository.assignPosition(position.positionId, created.id);
    }
  }
}
