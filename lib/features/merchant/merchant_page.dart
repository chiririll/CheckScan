import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/merchant/merchant.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/dialogs.dart';

class MerchantPage extends StatelessWidget {
  const MerchantPage({super.key, required this.state, required this.merchantId});

  final AppState state;
  final String merchantId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final merchants = state.merchants;
        final merchant = merchants.byId(merchantId);
        if (merchant == null) {
          return Scaffold(appBar: AppBar(title: Text(l10n.merchantsTitle)));
        }
        final parent = merchants.byId(merchant.parentId);
        return Scaffold(
          appBar: AppBar(title: Text(merchant.name)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.merchantName),
                subtitle: Text(merchant.name),
                onTap: () async {
                  final name = await promptText(context, title: l10n.merchantName, initial: merchant.name, confirm: l10n.save);
                  if (name != null) await merchants.update(merchant.id, name: name);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.merchantNetwork),
                subtitle: Text(parent?.name ?? l10n.merchantNoNetwork),
                onTap: () => _pickParent(context, merchant),
              ),
              const SizedBox(height: 12),
              Text(l10n.merchantAliases, style: AppText.title),
              const SizedBox(height: 8),
              for (final alias in merchant.aliases)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(alias.name ?? alias.taxId ?? '—'),
                  subtitle: alias.taxId == null || alias.name == null ? null : Text(alias.taxId!),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () async {
                    final name = await promptText(context, title: l10n.addAlias, confirm: l10n.save);
                    if (name != null) await merchants.addAlias(merchant.id, name: name);
                  },
                  child: Text(l10n.addAlias),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickParent(BuildContext context, Merchant merchant) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(l10n.merchantNoNetwork), onTap: () => Navigator.pop(context, '')),
            for (final other in state.merchants.all)
              if (other.id != merchant.id)
                ListTile(
                  title: Text(other.name),
                  selected: other.id == merchant.parentId,
                  onTap: () => Navigator.pop(context, other.id),
                ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await state.merchants.update(
      merchant.id,
      parentId: selected.isEmpty ? null : selected,
      clearParent: selected.isEmpty,
    );
  }
}
