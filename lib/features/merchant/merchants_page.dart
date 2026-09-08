import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/merchant/merchant.dart';
import '../../l10n/app_localizations.dart';
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
        return Scaffold(
          appBar: AppBar(title: Text(l10n.merchantsTitle)),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: state.merchantList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final merchant = state.merchantList[index];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFE4E4E4)),
                ),
                title: Text(merchant.name),
                subtitle: Text(_subtitle(merchant, l10n)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => MerchantPage(state: state, merchantId: merchant.id)),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _subtitle(Merchant merchant, AppLocalizations l10n) {
    final policy = merchant.ignoresItems ? l10n.merchantPolicyIgnore : l10n.merchantPolicyParse;
    final parent = merchant.parentId == null ? null : state.merchantById(merchant.parentId);
    final network = parent == null ? l10n.merchantNoNetwork : parent.name;
    return '$policy · $network';
  }
}
