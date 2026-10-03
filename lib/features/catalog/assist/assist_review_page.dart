import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/catalog/assist/assist_draft.dart';
import '../../../core/state/app_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/bottom_action.dart';
import '../../widgets/dialogs.dart';
import '../catalog_nav.dart';
import '../catalog_trail.dart';

class AssistReviewPage extends StatefulWidget {
  const AssistReviewPage({super.key, required this.state, required this.draft});

  final AppState state;
  final AssistDraft draft;

  @override
  State<AssistReviewPage> createState() => _AssistReviewPageState();
}

class _AssistReviewPageState extends State<AssistReviewPage> {
  late AssistDraft _draft = widget.draft;

  Future<void> _rename(int index) async {
    final l10n = AppLocalizations.of(context);
    final name = await promptText(
      context,
      title: l10n.productName,
      initial: _draft.products[index].name,
      confirm: l10n.save,
    );
    if (name == null || !mounted) return;
    setState(() => _draft = _draft.renameProduct(index, name));
  }

  Future<void> _apply() async {
    await widget.state.catalog.applyAssistDraft(_draft);
    if (mounted) Navigator.pop(context);
  }

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
          for (var i = 0; i < _draft.products.length; i++)
            _ProductCard(
              product: _draft.products[i],
              onRename: () => _rename(i),
              onDismiss: () => setState(() => _draft = _draft.withoutProduct(i)),
              onRemovePosition: (id) => setState(() => _draft = _draft.withoutPosition(i, id)),
            ),
          if (_draft.unmatched.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l10n.assistUnmatched, style: AppText.title),
            const SizedBox(height: 8),
            for (var i = 0; i < _draft.unmatched.length; i++)
              _UnmatchedTile(
                line: _draft.unmatched[i].raw,
                onDismiss: () => setState(() => _draft = _draft.withoutUnmatched(i)),
              ),
          ],
        ],
      ),
      bottomNavigationBar: BottomAction(label: l10n.assistApply, onPressed: _draft.canApply ? _apply : null),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onRename,
    required this.onDismiss,
    required this.onRemovePosition,
  });

  final AssistDraftProduct product;
  final VoidCallback onRename;
  final VoidCallback onDismiss;
  final ValueChanged<String> onRemovePosition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: AppShapes.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(product.name, style: AppText.title)),
                IconButton(tooltip: l10n.rename, onPressed: onRename, icon: const Icon(Icons.edit_outlined, size: 20)),
                IconButton(tooltip: l10n.deleteReceipt, onPressed: onDismiss, icon: const Icon(Icons.close)),
              ],
            ),
            for (final position in product.positions)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(position.displayName),
                trailing: IconButton(
                  onPressed: () => onRemovePosition(position.positionId),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UnmatchedTile extends StatelessWidget {
  const _UnmatchedTile({required this.line, required this.onDismiss});

  final String line;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(line, style: TextStyle(color: Colors.grey.shade800)),
      trailing: IconButton(onPressed: onDismiss, icon: const Icon(Icons.close, size: 18)),
    );
  }
}
