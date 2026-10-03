import 'package:flutter/material.dart';

import '../../core/catalog/product_receipts.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../history/receipt_day_list.dart';
import '../widgets/centered_message.dart';
import 'catalog_trail.dart';

class ProductReceiptsPage extends StatelessWidget {
  const ProductReceiptsPage({super.key, required this.state, required this.productId});

  final AppState state;
  final String productId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final product = state.catalog.productById(productId);
        final receipts = receiptsContainingProduct(
          purchases: state.catalog.purchases,
          receipts: state.receipts,
          productId: productId,
        );
        return Scaffold(
          appBar: CatalogAppBar(
            title: l10n.productReceipts,
            ancestors: [
              if (product != null) CatalogCrumb(label: product.name, onTap: () => Navigator.pop(context)),
            ],
          ),
          body: receipts.isEmpty
              ? CenteredMessage(title: l10n.productReceiptsEmptyTitle, body: l10n.productReceiptsEmptyBody)
              : ReceiptDayList(state: state, receipts: receipts),
        );
      },
    );
  }
}
