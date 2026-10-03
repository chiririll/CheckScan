import 'package:flutter/material.dart';

import '../../core/merchant/merchant.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/card_tile.dart';
import '../widgets/navigation.dart';
import 'merchant_page.dart';

class MerchantsPage extends StatelessWidget {
  const MerchantsPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final merchants = state.merchants.all;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.merchantsTitle)),
          body: CardList(
            itemCount: merchants.length,
            itemBuilder: (context, index) {
              final merchant = merchants[index];
              return CardTile(
                title: merchant.name,
                subtitle: _subtitle(merchant, l10n),
                onTap: () => pushPage<void>(context, MerchantPage(state: state, merchantId: merchant.id)),
              );
            },
          ),
        );
      },
    );
  }

  String _subtitle(Merchant merchant, AppLocalizations l10n) {
    final policy = merchant.ignoresItems ? l10n.merchantPolicyIgnore : l10n.merchantPolicyParse;
    final network = state.merchants.byId(merchant.parentId)?.name ?? l10n.merchantNoNetwork;
    return '$policy · $network';
  }
}
