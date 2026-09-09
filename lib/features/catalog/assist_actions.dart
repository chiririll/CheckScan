import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_state.dart';
import '../../core/catalog/assist_draft.dart';
import '../../core/catalog/assist_match.dart';
import '../../core/catalog/assist_prompt.dart';
import '../../l10n/app_localizations.dart';
import 'assist_review_page.dart';

Future<void> copyAssistPrompt(BuildContext context, AppState state) async {
  final l10n = AppLocalizations.of(context);
  final unassigned = state.catalog.unassigned;
  if (unassigned.isEmpty) return;
  await Clipboard.setData(ClipboardData(text: buildAssistPrompt(unassigned)));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.assistCopied)));
}

Future<void> pasteAssistReply(BuildContext context, AppState state) async {
  final l10n = AppLocalizations.of(context);
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final result = reviewAssistReply(data?.text ?? '', state.catalog.unassigned);
  if (!context.mounted) return;
  if (!result.isOk) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_pasteError(l10n, result.error!))));
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => AssistReviewPage(state: state, draft: result.draft!)),
  );
}

String _pasteError(AppLocalizations l10n, AssistParseError error) {
  return switch (error) {
    AssistParseError.empty => l10n.assistErrorEmpty,
    AssistParseError.noProducts => l10n.assistErrorNoProducts,
    AssistParseError.nothingToApply => l10n.assistErrorNothing,
  };
}
