import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/catalog/product_receipts.dart';
import '../../core/format.dart';
import '../../core/models/receipt_record.dart';
import '../../l10n/app_localizations.dart';
import '../history/receipt_card.dart';
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
        final groups = <String, List<ReceiptRecord>>{};
        for (final receipt in receipts) {
          final date = receipt.issuedAt ?? receipt.scannedAt;
          groups.putIfAbsent(DateFormat('yyyy-MM-dd').format(date), () => []).add(receipt);
        }
        return Scaffold(
          appBar: CatalogAppBar(
            title: l10n.productReceipts,
            ancestors: [
              if (product != null) CatalogCrumb(label: product.name, onTap: () => Navigator.pop(context)),
            ],
          ),
          body: receipts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.productReceiptsEmptyTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.productReceiptsEmptyBody,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, top: 8),
                        child: Text(
                          formatDayHeader(DateTime.parse(entry.key)),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ),
                      for (final receipt in entry.value) ReceiptCard(receipt: receipt, state: state),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
