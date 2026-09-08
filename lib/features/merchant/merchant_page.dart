import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/catalog/category_label.dart';
import '../../core/merchant/merchant.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_dialogs.dart';
import '../catalog/category_picker.dart';

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
        final merchant = state.merchantById(merchantId);
        if (merchant == null) {
          return Scaffold(appBar: AppBar(title: Text(l10n.merchantsTitle)));
        }
        final parent = merchant.parentId == null ? null : state.merchantById(merchant.parentId);
        final category = merchant.categoryId == null ? null : state.catalog.categoryById(merchant.categoryId!);
        return Scaffold(
          appBar: AppBar(title: Text(merchant.name)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.productName),
                subtitle: Text(merchant.name),
                onTap: () async {
                  final name = await promptText(context, title: l10n.productName, initial: merchant.name, confirm: l10n.save);
                  if (name == null) return;
                  await state.merchants.update(merchant.id, name: name);
                  await state.reloadMerchants();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.merchantNetwork),
                subtitle: Text(parent?.name ?? l10n.merchantNoNetwork),
                onTap: () => _pickParent(context, merchant),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.merchantPolicy),
                trailing: DropdownButton<String>(
                  value: merchant.policy,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: MerchantPolicy.parse, child: Text(l10n.merchantPolicyParse)),
                    DropdownMenuItem(value: MerchantPolicy.ignore, child: Text(l10n.merchantPolicyIgnore)),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    await state.merchants.update(merchant.id, policy: value);
                    await state.reload();
                    await state.reloadMerchants();
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.merchantCategory),
                subtitle: Text(category == null ? l10n.noCategory : categoryTitle(category, l10n)),
                onTap: () async {
                  final selected = await pickAssignableCategory(
                    context: context,
                    catalog: state.catalog,
                    currentId: merchant.categoryId,
                    topsOnly: true,
                  );
                  if (selected == null) return;
                  if (selected.isEmpty) {
                    await state.merchants.update(merchant.id, clearCategory: true);
                  } else {
                    await state.merchants.update(merchant.id, categoryId: selected);
                  }
                  await state.reloadMerchants();
                },
              ),
              const SizedBox(height: 12),
              Text(l10n.merchantAliases, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    if (name == null) return;
                    await state.merchants.addAlias(merchant.id, name: name);
                    await state.reloadMerchants();
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
            for (final other in state.merchantList)
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
    if (selected.isEmpty) {
      await state.merchants.update(merchant.id, clearParent: true);
    } else {
      await state.merchants.update(merchant.id, parentId: selected);
    }
    await state.reloadMerchants();
  }
}
