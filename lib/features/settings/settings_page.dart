import 'package:flutter/material.dart';

import '../../core/scan/native_adapter.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';

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
                Text(l10n.providerSecrets, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text(l10n.providerTokenHint, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 12),
                for (final field in state.settingFields)
                  _SecretField(state: state, field: field, title: l10n.providerToken(field.label)),
                const SizedBox(height: 16),
              ],
              Text(l10n.integrations, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              _row(l10n.integration1c, l10n.soon),
              _row(l10n.integrationExport, l10n.soon),
              _row(l10n.integrationCloud, l10n.soon),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String title, String chip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(chip, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SecretField extends StatefulWidget {
  const _SecretField({required this.state, required this.field, required this.title});

  final AppState state;
  final SettingField field;
  final String title;

  @override
  State<_SecretField> createState() => _SecretFieldState();
}

class _SecretFieldState extends State<_SecretField> {
  late final TextEditingController _controller;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.settings.values[widget.field.key] ?? '');
  }

  @override
  void dispose() {
    _save();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.state.setSetting(widget.field.key, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controller,
        obscureText: _obscure,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: widget.title,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        onEditingComplete: _save,
        onTapOutside: (_) => _save(),
      ),
    );
  }
}
