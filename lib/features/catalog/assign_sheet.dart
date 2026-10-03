import 'package:flutter/material.dart';

import '../../core/catalog/model/catalog_position.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../labels/unit_labels.dart';
import '../widgets/dialogs.dart';
import '../widgets/navigation.dart';
import 'product_page.dart';
import 'widgets/position_amount.dart';

/// Bottom sheet to attach a position to an existing or a new product.
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

  Future<void> _createProduct(BuildContext context, CatalogPosition position) async {
    final l10n = AppLocalizations.of(context);
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
    await pushPage<void>(context, ProductPage(state: state, productId: product.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final catalog = state.catalog;
        final position = catalog.positionById(positionId);
        if (position == null) {
          return const SizedBox(height: 120, child: Center(child: Text('—')));
        }
        final product = position.productId == null ? null : catalog.productById(position.productId!);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(position.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 12),
                PositionAmountTile(catalog: catalog, position: position, product: product),
                const SizedBox(height: 12),
                FilledButton(onPressed: () => _createProduct(context, position), child: Text(l10n.newProduct)),
                if (catalog.products.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final product in catalog.products)
                          ListTile(
                            dense: true,
                            title: Text(product.name),
                            subtitle: product.unit == null ? null : Text(unitLabel(product.unit, l10n)),
                            onTap: () async {
                              await catalog.assignPosition(position.id, product.id);
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
