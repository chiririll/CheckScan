import 'package:flutter/material.dart';

import '../../core/shopping/shopping_list.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/product_page.dart';
import '../labels/unit_labels.dart';
import '../widgets/card_tile.dart';
import '../widgets/centered_message.dart';
import '../widgets/navigation.dart';

class ListPage extends StatelessWidget {
  const ListPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.listTitle)),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final lines = buildShoppingList(
            purchases: state.catalog.purchases,
            products: state.catalog.products,
            positions: state.catalog.positions,
            receipts: state.receipts,
            resolver: state.catalog.resolver,
            merchants: state.merchants.all,
            fallbackMerchant: l10n.receiptTitle,
          );
          if (lines.isEmpty) return CenteredMessage(title: l10n.listEmptyTitle, body: l10n.listEmptyBody);
          return CardList(
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final line = lines[index];
              final pack = formatCatalogUnit(line.unit, line.packSize, l10n);
              final cheaper = line.cheaperNetwork;
              return CardTile(
                title: line.name,
                subtitle: [
                  l10n.listPacks(line.packs),
                  if (pack.isNotEmpty) pack,
                  if (cheaper != null) l10n.cheaperAt(cheaper),
                ].join(' · '),
                onTap: () => pushPage<void>(context, ProductPage(state: state, productId: line.productId)),
              );
            },
          );
        },
      ),
    );
  }
}
