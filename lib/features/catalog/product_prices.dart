import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/catalog/model/catalog_product.dart';
import '../../core/catalog/pricing/price_point.dart';
import '../../core/format/format.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../labels/unit_labels.dart';

/// Unit price, cheapest networks and price history of one product.
class ProductPrices extends StatelessWidget {
  const ProductPrices({super.key, required this.state, required this.product});

  final AppState state;
  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = state.catalog;
    final points = collectPricePoints(
      receipts: state.receipts,
      resolver: catalog.resolver,
      merchants: state.merchants.all,
      fallbackMerchant: l10n.receiptTitle,
    );
    final mine = pointsForProduct(points, product.id);
    if (mine.isEmpty) return const SizedBox.shrink();

    final headline = headlinePrice(productPoints: mine, items: catalog.positions, product: product);
    final networks = cheaperNetworks(mine);
    final currency = headline?.currency ?? mine.first.currency;
    final pack = headline == null ? null : catalog.positionById(headline.itemId);
    final packLabel = pack == null ? '' : formatPositionPack(pack, product, l10n);
    final unit = headline?.unit;
    final perUnit = headline?.perUnit;
    final history = [for (final point in mine) if (point.perUnit != null && point.unit != null) point];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(l10n.pricesBlock, style: AppText.title),
        const SizedBox(height: 8),
        if (perUnit != null && unit != null) ...[
          Text(
            formatUnitPrice(perUnit, unit, currency, l10n),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          if (packLabel.isNotEmpty) Text(l10n.referencePack(packLabel), style: AppText.mutedSmall),
        ] else
          Text(l10n.noUnitPrice, style: AppText.muted),
        if (networks.isNotEmpty && unit != null) ...[
          const SizedBox(height: 8),
          for (final network in networks)
            _PriceRow(
              bottom: 4,
              label: Text(
                network.networkName,
                style: TextStyle(fontWeight: network == networks.first ? FontWeight.w600 : FontWeight.w400),
              ),
              price: Text(formatUnitPrice(network.perUnit, unit, currency, l10n)),
            ),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.priceDynamics, style: AppText.title),
          const SizedBox(height: 8),
          for (final point in history)
            _PriceRow(
              bottom: 6,
              leading: Text(formatDayShort(point.at), style: AppText.mutedSmall),
              label: Text(point.networkName, style: const TextStyle(fontSize: 13)),
              price: Text(
                formatUnitPrice(point.perUnit!, point.unit!, point.currency, l10n),
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.price, required this.bottom, this.leading});

  final Widget label;
  final Widget price;
  final double bottom;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Row(
        children: [
          if (leading != null) SizedBox(width: 88, child: leading),
          Expanded(child: label),
          price,
        ],
      ),
    );
  }
}
