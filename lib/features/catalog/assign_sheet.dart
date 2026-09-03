import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/catalog/catalog_position.dart';
import 'unit_labels.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import 'catalog_dialogs.dart';
import 'product_page.dart';

Future<void> showAssignSheet({
  required BuildContext context,
  required AppState state,
  required CatalogPosition position,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _AssignSheet(state: state, positionId: position.id),
    ),
  );
}

class _AssignSheet extends StatelessWidget {
  const _AssignSheet({required this.state, required this.positionId});

  final AppState state;
  final String positionId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final position = state.catalog.positionById(positionId);
        if (position == null) {
          return const SizedBox(height: 120, child: Center(child: Text('—')));
        }
        final suggestions = state.catalog.suggestionsFor(position);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(position.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 12),
                _AmountRow(state: state, position: position),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final other in suggestions.take(3))
                        ActionChip(
                          label: Text(l10n.mergeWith(other.displayName), overflow: TextOverflow.ellipsis),
                          onPressed: () async {
                            await state.catalog.mergePositions(sourceId: position.id, targetId: other.id);
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    final name = await promptText(
                      context,
                      title: l10n.newProduct,
                      initial: position.displayName,
                      confirm: l10n.createAndAssign,
                    );
                    if (name == null) return;
                    final product = await state.catalog.createProduct(name: name, positionId: position.id);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => ProductPage(state: state, productId: product.id)),
                    );
                  },
                  child: Text(l10n.newProduct),
                ),
                if (state.catalog.products.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final product in state.catalog.products)
                          ListTile(
                            dense: true,
                            title: Text(product.name),
                            subtitle: product.unit == null ? null : Text(unitLabel(product.unit, l10n)),
                            onTap: () async {
                              await state.catalog.assignPosition(position.id, product.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.state, required this.position});

  final AppState state;
  final CatalogPosition position;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final product = position.productId == null ? null : state.catalog.productById(position.productId!);
    final pack = formatPositionPack(position, product, l10n);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(l10n.unitSize, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      trailing: Text(
        pack.isEmpty ? l10n.unitNone : pack,
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
      onTap: () => editPositionAmount(
        context: context,
        catalog: state.catalog,
        positionId: position.id,
        current: position.unitSize,
      ),
    );
  }
}
