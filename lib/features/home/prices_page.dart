import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/product_page.dart';
import '../catalog/unit_labels.dart';
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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.pricesEmptyTitle, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(l10n.pricesEmptyBody, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: rows.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final row = rows[index];
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFFE4E4E4)),
                  ),
                  title: Text(row.productName),
                  subtitle: Text(
                    [
                      formatUnitPrice(row.perUnit, row.unit, currency, l10n),
                      l10n.cheaperAt(row.networkName),
                      if (row.shift != null) _shiftLabel(row.shift!),
                    ].join(' · '),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => ProductPage(state: state, productId: row.productId)),
                  ),
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
