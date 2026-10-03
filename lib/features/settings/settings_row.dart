import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/navigation.dart';

/// Outlined settings row; tappable when [onTap] is set.
class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.title, required this.trailing, this.onTap});

  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        shape: AppShapes.card,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppShapes.radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Row that runs a share/export and shows progress; no receipts → a hint instead.
class ExportRow extends StatefulWidget {
  const ExportRow({super.key, required this.title, required this.icon, required this.state, required this.export});

  final String title;
  final IconData icon;
  final AppState state;
  final Future<void> Function() export;

  @override
  State<ExportRow> createState() => _ExportRowState();
}

class _ExportRowState extends State<ExportRow> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    if (widget.state.receipts.isEmpty) {
      showSnack(context, l10n.exportEmpty);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.export();
    } catch (_) {
      if (mounted) showSnack(context, l10n.exportFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      title: widget.title,
      onTap: _busy ? null : _run,
      trailing: _busy
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(widget.icon, size: 18, color: AppColors.muted),
    );
  }
}
