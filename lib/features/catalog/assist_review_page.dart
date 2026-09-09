import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/catalog/assist_draft.dart';
import '../../core/catalog/category_label.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import 'catalog_nav.dart';
import 'catalog_trail.dart';
import 'unit_labels.dart';

class AssistReviewPage extends StatefulWidget {
  const AssistReviewPage({super.key, required this.state, required this.draft});

  final AppState state;
  final AssistDraft draft;

  @override
  State<AssistReviewPage> createState() => _AssistReviewPageState();
}

class _AssistReviewPageState extends State<AssistReviewPage> {
  late AssistDraft _draft = widget.draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CatalogAppBar(
        title: l10n.assistReview,
        ancestors: [
          CatalogCrumb(label: l10n.catalogTitle, onTap: () => openCatalog(context, widget.state)),
          CatalogCrumb(label: l10n.catalogUnassigned, onTap: () => Navigator.pop(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (_draft.skippedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(l10n.assistSkippedSome, style: TextStyle(color: Colors.grey.shade700)),
            ),
          if (_draft.newCategories.isNotEmpty) ...[
            Text(l10n.assistNewCategories, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in _draft.newCategories)
                  InputChip(
                    label: Text(category.name),
                    onDeleted: () => setState(() => _draft = _draft.withoutCategory(category.key)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Text(l10n.catalogProducts, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (var i = 0; i < _draft.products.length; i++) _ProductCard(state: widget.state, draft: _draft, index: i, onChanged: (next) => setState(() => _draft = next)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FilledButton(
            onPressed: _draft.products.isEmpty && _draft.newCategories.isEmpty
                ? null
                : () async {
                    await widget.state.catalog.applyAssistDraft(_draft);
                    if (context.mounted) Navigator.pop(context);
                  },
            child: Text(l10n.assistApply),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.state, required this.draft, required this.index, required this.onChanged});

  final AppState state;
  final AssistDraft draft;
  final int index;
  final ValueChanged<AssistDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final product = draft.products[index];
    final categoryName = _categoryLabel(product, l10n);
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE4E4E4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                IconButton(
                  tooltip: l10n.deleteReceipt,
                  onPressed: () => onChanged(draft.withoutProduct(index)),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (categoryName != null || product.unit != null)
              Text(
                [if (categoryName != null) categoryName, if (product.unit != null) unitLabel(product.unit, l10n)].join(' · '),
                style: const TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            for (final position in product.positions)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(state.catalog.positionById(position.id)?.displayName ?? position.id),
                trailing: IconButton(
                  onPressed: () => onChanged(draft.withoutPosition(index, position.id)),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _categoryLabel(AssistDraftProduct product, AppLocalizations l10n) {
    if (product.newCategoryKey != null) {
      for (final category in draft.newCategories) {
        if (category.key == product.newCategoryKey) return category.name;
      }
    }
    if (product.existingCategoryId == null) return null;
    final category = state.catalog.categoryById(product.existingCategoryId!);
    return category == null ? null : categoryTitle(category, l10n);
  }
}
