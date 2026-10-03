import 'package:flutter/material.dart';

import '../../../core/catalog/assist/assist_clipboard.dart';
import '../../../core/catalog/assist/assist_draft.dart';
import '../../../core/catalog/assist/assist_log.dart';
import '../../../core/catalog/assist/assist_match.dart';
import '../../../core/catalog/model/catalog_position.dart';
import '../../../l10n/app_localizations.dart';
import 'assist_errors.dart';

const assistPasteFieldKey = Key('assist-paste-field');
const assistPasteSubmitKey = Key('assist-paste-submit');

Future<AssistDraft?> showAssistPasteSheet({
  required BuildContext context,
  required List<CatalogPosition> unassigned,
  String initial = '',
  String? initialError,
}) {
  return showDialog<AssistDraft>(
    context: context,
    builder: (context) => _AssistPasteDialog(unassigned: unassigned, initial: initial, initialError: initialError),
  );
}

class _AssistPasteDialog extends StatefulWidget {
  const _AssistPasteDialog({required this.unassigned, required this.initial, this.initialError});

  final List<CatalogPosition> unassigned;
  final String initial;
  final String? initialError;

  @override
  State<_AssistPasteDialog> createState() => _AssistPasteDialogState();
}

class _AssistPasteDialogState extends State<_AssistPasteDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);
  late String? _error = widget.initialError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final text = await resolveAssistPaste(fieldText: _controller.text);
    if (!mounted) return;
    assistLog('sheet submit len=${text.length} preview="${assistPreview(text)}"');
    final result = reviewAssistReply(text, widget.unassigned);
    if (!result.isOk) {
      final message = assistErrorText(l10n, result.error!);
      assistLog('sheet fail ${result.error} / $message');
      setState(() => _error = message);
      return;
    }
    assistLog('sheet ok → review');
    Navigator.pop(context, result.draft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.assistPasteReply),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: assistPasteFieldKey,
            controller: _controller,
            autofocus: true,
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: l10n.assistPasteHint,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(key: assistPasteSubmitKey, onPressed: _submit, child: Text(l10n.assistPasteShort)),
      ],
    );
  }
}
