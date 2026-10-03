import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

/// Single-line text prompt. Returns the trimmed text, or null on cancel
/// (and on empty input unless [allowEmpty]).
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String? initial,
  required String confirm,
  bool allowEmpty = false,
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (context) => _PromptDialog(title: title, initial: initial, confirm: confirm),
  );
  if (result == null) return null;
  if (result.isEmpty && !allowEmpty) return null;
  return result;
}

/// Destructive confirmation; true only when [confirm] was tapped.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: Text(confirm),
        ),
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
      ],
    ),
  );
  return result == true;
}

/// Message with a single "got it" button.
Future<void> showNotice(BuildContext context, {String? title, required String body}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: title == null ? null : Text(title),
      content: Text(body),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).gotIt)),
      ],
    ),
  );
}

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({required this.title, required this.confirm, this.initial});

  final String title;
  final String? initial;
  final String confirm;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final _controller = TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, _controller.text.trim()), child: Text(widget.confirm)),
      ],
    );
  }
}
