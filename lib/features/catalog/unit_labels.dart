import '../../core/catalog/item_unit.dart';
import '../../core/format.dart';
import '../../l10n/app_localizations.dart';

String unitLabel(ItemUnit? unit, AppLocalizations l10n) {
  return switch (unit) {
    ItemUnit.piece => l10n.unitPiece,
    ItemUnit.pack => l10n.unitPack,
    ItemUnit.kg => l10n.unitKg,
    ItemUnit.g => l10n.unitG,
    ItemUnit.l => l10n.unitL,
    ItemUnit.ml => l10n.unitMl,
    null => l10n.unitNone,
  };
}

String formatCatalogUnit(ItemUnit? unit, double? size, AppLocalizations l10n) {
  if (unit == null) return '';
  final label = unitLabel(unit, l10n);
  if (size == null) return label;
  return '${formatQty(size)} $label';
}
