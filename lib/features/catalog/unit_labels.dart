import '../../core/catalog/catalog_position.dart';
import '../../core/catalog/catalog_product.dart';
import '../../core/catalog/item_unit.dart';
import '../../core/catalog/unit_parser.dart';
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
  if (unit == null && size == null) return '';
  if (unit == null) return formatQty(size!);
  final label = unitLabel(unit, l10n);
  if (size == null) return label;
  return '${formatQty(size)} $label';
}

String formatPositionPack(CatalogPosition position, CatalogProduct? product, AppLocalizations l10n) {
  final parsed = parseItemUnit(position.displayName);
  final unit = product?.unit ?? parsed?.unit;
  final size = position.unitSize ?? parsed?.size;
  return formatCatalogUnit(unit, size, l10n);
}

String formatPositionMeta(CatalogPosition position, CatalogProduct? product, AppLocalizations l10n) {
  return [
    formatPositionPack(position, product, l10n),
    ?position.brand,
  ].where((part) => part.isNotEmpty).join(' · ');
}
