import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/catalog/catalog_product.dart';
import '../../core/catalog/price_point.dart';
import '../../core/catalog/purchase_cache.dart';
import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import 'unit_labels.dart';

class ProductPrices extends StatelessWidget {
  const ProductPrices({super.key, required this.state, required this.product});

  final AppState state;
  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = collectPricePoints(
      receipts: state.receipts,
      resolver: state.catalog.resolver,
      merchants: state.merchantList,
      ignoreMerchantIds: ignoreMerchantIdsOf(state.merchantList),
      fallbackMerchant: l10n.receiptTitle,
    );
    final mine = pointsForProduct(points, product.id);
    if (mine.isEmpty) return const SizedBox.shrink();

    final headline = headlinePrice(
      productPoints: mine,
      items: state.catalog.positions,
      product: product,
    );
    final networks = cheaperNetworks(mine);
    final currency = headline?.currency ?? mine.first.currency;
    final pack = headline == null ? null : state.catalog.positionById(headline.itemId);
    final packLabel = pack == null ? '' : formatPositionPack(pack, product, l10n);
    final unit = headline?.unit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(l10n.pricesBlock, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (headline?.perUnit != null && unit != null) ...[
          Text(
            formatUnitPrice(headline!.perUnit!, unit, currency, l10n),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          if (packLabel.isNotEmpty)
            Text(l10n.referencePack(packLabel), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ] else
          Text(l10n.noUnitPrice, style: TextStyle(color: Colors.grey.shade600)),
        if (networks.isNotEmpty && unit != null) ...[
          const SizedBox(height: 8),
          for (final network in networks)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      network.networkName,
                      style: TextStyle(fontWeight: network == networks.first ? FontWeight.w600 : FontWeight.w400),
                    ),
                  ),
                  Text(formatUnitPrice(network.perUnit, unit, currency, l10n)),
                ],
              ),
            ),
        ],
        if (mine.any((point) => point.perUnit != null)) ...[
          const SizedBox(height: 12),
          Text(l10n.priceDynamics, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final point in mine.where((point) => point.perUnit != null && point.unit != null))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 88,
                    child: Text(formatDayShort(point.at), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ),
                  Expanded(child: Text(point.networkName, style: const TextStyle(fontSize: 13))),
                  Text(formatUnitPrice(point.perUnit!, point.unit!, point.currency, l10n), style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
