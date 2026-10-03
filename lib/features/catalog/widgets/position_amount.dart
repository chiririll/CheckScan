import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/catalog/catalog_store.dart';
import '../../../core/catalog/model/catalog_position.dart';
import '../../../core/catalog/model/catalog_product.dart';
import '../../../core/format/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../labels/unit_labels.dart';
import '../../widgets/dialogs.dart';

/// Asks for the pack size; an empty answer clears it.
Future<void> editPositionAmount({
  required BuildContext context,
  required CatalogStore catalog,
  required String positionId,
  double? current,
}) async {
  final l10n = AppLocalizations.of(context);
  final raw = await promptText(
    context,
    title: l10n.unitSize,
    initial: current == null ? '' : formatQty(current),
    confirm: l10n.save,
    allowEmpty: true,
  );
  if (raw == null) return;
  if (raw.isEmpty) {
    await catalog.updatePosition(positionId, clearAmount: true);
    return;
  }
  final size = parseDecimal(raw);
  if (size != null) await catalog.updatePosition(positionId, unitSize: size);
}

/// "Pack size" row that opens [editPositionAmount].
class PositionAmountTile extends StatelessWidget {
  const PositionAmountTile({super.key, required this.catalog, required this.position, this.product});

  final CatalogStore catalog;
  final CatalogPosition position;
  final CatalogProduct? product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pack = formatPositionPack(position, product, l10n);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(l10n.unitSize, style: AppText.mutedSmall),
      trailing: Text(
        pack.isEmpty ? l10n.unitNone : pack,
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
      onTap: () => editPositionAmount(
        context: context,
        catalog: catalog,
        positionId: position.id,
        current: position.unitSize,
      ),
    );
  }
}
