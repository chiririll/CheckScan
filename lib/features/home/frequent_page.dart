import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/product_page.dart';
import '../widgets/card_tile.dart';
import '../widgets/centered_message.dart';
import '../widgets/navigation.dart';
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
          ? CenteredMessage(title: l10n.frequentEmptyTitle, body: l10n.frequentEmptyBody)
          : CardList(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return CardTile(
                  title: item.name,
                  trailing: Text(l10n.timesCount(item.count), style: AppText.muted),
                  onTap: () => pushPage<void>(context, ProductPage(state: state, productId: item.productId)),
                );
              },
            ),
    );
  }
}
