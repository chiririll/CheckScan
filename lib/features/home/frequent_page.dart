import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/product_page.dart';
import 'home_dashboard.dart';

class FrequentPage extends StatelessWidget {
  const FrequentPage({super.key, required this.state, required this.items});

  final AppState state;
  final List<FrequentItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.frequentBlock)),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.frequentEmptyTitle, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(l10n.frequentEmptyBody, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFFE4E4E4)),
                  ),
                  title: Text(item.name),
                  trailing: Text(l10n.timesCount(item.count), style: TextStyle(color: Colors.grey.shade600)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => ProductPage(state: state, productId: item.productId)),
                  ),
                );
              },
            ),
    );
  }
}
