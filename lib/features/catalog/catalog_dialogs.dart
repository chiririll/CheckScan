import 'package:flutter/material.dart';

import '../../core/catalog/catalog_store.dart';
import '../../core/format.dart';
import '../../l10n/app_localizations.dart';

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

Future<void> editPositionAmount({
  required BuildContext context,
  required CatalogStore catalog,
  required String positionId,
  double? current,
}) async {
  final l10n = AppLocalizations.of(context);
  final raw = await promptText(
    context,
    title: l10n.unitSize,
    initial: current == null ? '' : formatQty(current),
    confirm: l10n.save,
    allowEmpty: true,
  );
  if (raw == null) return;
  if (raw.isEmpty) {
    await catalog.updatePosition(positionId, clearAmount: true);
    return;
  }
  final size = double.tryParse(raw.replaceAll(',', '.'));
  if (size != null) await catalog.updatePosition(positionId, unitSize: size);
}

Future<void> editPositionBrand({
  required BuildContext context,
  required CatalogStore catalog,
  required String positionId,
  String? current,
}) async {
  final l10n = AppLocalizations.of(context);
  final raw = await promptText(
    context,
    title: l10n.positionBrand,
    initial: current ?? '',
    confirm: l10n.save,
    allowEmpty: true,
  );
  if (raw == null) return;
  if (raw.isEmpty) {
    await catalog.updatePosition(positionId, clearBrand: true);
    return;
  }
  await catalog.updatePosition(positionId, brand: raw);
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
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
  }

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
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
          child: Text(confirm),
        ),
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
      ],
    ),
  );
  return result == true;
}
