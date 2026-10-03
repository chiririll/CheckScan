import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/export/eq_jsonl_share.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../merchant/merchants_page.dart';
import '../widgets/navigation.dart';
import 'secret_field.dart';
import 'settings_row.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(l10n.settingsTitle),
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.settingFields.isNotEmpty) ...[
                Text(l10n.providerSecrets, style: AppText.muted),
                const SizedBox(height: 8),
                Text(l10n.providerTokenHint, style: AppText.mutedSmall),
                const SizedBox(height: 12),
                for (final field in state.settingFields)
                  SecretField(state: state, field: field, title: l10n.providerToken(field.label)),
                const SizedBox(height: 16),
              ],
              SettingsRow(
                title: l10n.merchantsTitle,
                trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
                onTap: () => pushPage<void>(context, MerchantsPage(state: state)),
              ),
              const SizedBox(height: 16),
              Text(l10n.integrations, style: AppText.muted),
              const SizedBox(height: 8),
              SettingsRow(title: l10n.integration1c, trailing: _soon(l10n)),
              ExportRow(
                title: l10n.integrationExport,
                icon: Icons.share_outlined,
                state: state,
                export: () => shareEqJsonl(receipts: state.receipts, subject: l10n.exportShareSubject),
              ),
              SettingsRow(title: l10n.integrationCloud, trailing: _soon(l10n)),
            ],
          );
        },
      ),
    );
  }

  Widget _soon(AppLocalizations l10n) => Text(l10n.soon, style: const TextStyle(color: AppColors.muted, fontSize: 12));
}
