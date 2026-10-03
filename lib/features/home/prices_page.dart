import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/product_page.dart';
import '../labels/unit_labels.dart';
import '../widgets/card_tile.dart';
import '../widgets/centered_message.dart';
import '../widgets/navigation.dart';
import 'home_dashboard.dart';

class PricesPage extends StatelessWidget {
  const PricesPage({super.key, required this.state, required this.rows, required this.currency});

  final AppState state;
  final List<PriceRow> rows;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pricesBlock)),
      body: rows.isEmpty
          ? CenteredMessage(title: l10n.pricesEmptyTitle, body: l10n.pricesEmptyBody)
          : CardList(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                final shift = row.shift;
                return CardTile(
                  title: row.productName,
                  subtitle: [
                    formatUnitPrice(row.perUnit, row.unit, currency, l10n),
                    l10n.cheaperAt(row.networkName),
                    if (shift != null) _shiftLabel(shift),
                  ].join(' · '),
                  onTap: () => pushPage<void>(context, ProductPage(state: state, productId: row.productId)),
                );
              },
            ),
    );
  }
}

String _shiftLabel(double shift) {
  final pct = (shift.abs() * 100).toStringAsFixed(0);
  if (shift > 0.005) return '↑ $pct%';
  if (shift < -0.005) return '↓ $pct%';
  return '';
}
