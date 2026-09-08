import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/shopping/shopping_list.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/product_page.dart';
import '../catalog/unit_labels.dart';

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
            merchants: state.merchantList,
            fallbackMerchant: l10n.receiptTitle,
          );
          if (lines.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.listEmptyTitle, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(l10n.listEmptyBody, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: lines.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final line = lines[index];
              final pack = formatCatalogUnit(line.unit, line.packSize, l10n);
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFE4E4E4)),
                ),
                title: Text(line.name),
                subtitle: Text(
                  [
                    l10n.listPacks(line.packs),
                    if (pack.isNotEmpty) pack,
                    if (line.cheaperNetwork != null) l10n.cheaperAt(line.cheaperNetwork!),
                  ].join(' · '),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ProductPage(state: state, productId: line.productId)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
