import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/currency/currencies.dart';
import '../../core/format/format.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/dialogs.dart';
import '../widgets/navigation.dart';

/// The user's currency list: tab order on home and the choices for a manual receipt.
class CurrenciesPage extends StatelessWidget {
  const CurrenciesPage({super.key, required this.state});

  final AppState state;

  Future<void> _add(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final raw = await promptText(context, title: l10n.currenciesAddTitle, confirm: l10n.save);
    if (raw == null || !context.mounted) return;
    final code = normalizeCurrency(raw);
    if (code == null) {
      showSnack(context, l10n.currencyInvalid);
      return;
    }
    await state.setCurrencyOrder([...state.currencyOrder, code]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(l10n.currenciesTitle),
        actions: [
          IconButton(tooltip: l10n.currenciesAddTitle, icon: const Icon(Icons.add), onPressed: () => _add(context)),
        ],
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final order = state.currencyOrder;
          final suggestions = recentCurrencies(state.receipts).where((code) => !order.contains(code)).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.currenciesHint, style: AppText.mutedSmall),
              const SizedBox(height: 12),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorderItem: (from, to) {
                  final next = [...order];
                  next.insert(to, next.removeAt(from));
                  state.setCurrencyOrder(next);
                },
                children: [
                  for (final code in order)
                    ListTile(
                      key: ValueKey(code),
                      title: Text('$code · ${formatCurrencyLabel(code)}'),
                      trailing: Padding(
                        padding: const EdgeInsets.only(right: 32),
                        child: IconButton(
                          tooltip: l10n.currenciesRemove,
                          icon: const Icon(Icons.close),
                          onPressed: () => state.setCurrencyOrder([...order]..remove(code)),
                        ),
                      ),
                    ),
                ],
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.currenciesFromReceipts, style: AppText.muted),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final code in suggestions)
                      ActionChip(
                        label: Text(code),
                        avatar: const Icon(Icons.add, size: 16),
                        onPressed: () => state.setCurrencyOrder([...order, code]),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
