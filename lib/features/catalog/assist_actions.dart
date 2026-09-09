import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_state.dart';
import '../../core/catalog/assist_clipboard.dart';
import '../../core/catalog/assist_draft.dart';
import '../../core/catalog/assist_log.dart';
import '../../core/catalog/assist_match.dart';
import '../../core/catalog/assist_prompt.dart';
import '../../l10n/app_localizations.dart';
import 'assist_paste_sheet.dart';
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
  assistLog('paste tap');
  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(const Duration(milliseconds: 50));
  if (!context.mounted) {
    assistLog('paste abort: unmounted after menu');
    return;
  }

  final clip = await resolveAssistPaste();
  if (!context.mounted) return;

  final first = reviewAssistReply(clip, state.catalog.unassigned);
  if (!context.mounted) return;
  if (first.isOk) {
    assistLog('clipboard ok → review');
    await _openReview(context, state, first.draft!);
    return;
  }

  assistLog('clipboard fail ${first.error} / ${_pasteError(l10n, first.error!)} → paste sheet');
  final draft = await showAssistPasteSheet(
    context: context,
    unassigned: state.catalog.unassigned,
    initial: clip,
    initialError: _pasteError(l10n, first.error!),
  );
  if (!context.mounted) return;
  if (draft == null) {
    assistLog('paste sheet cancelled');
    return;
  }
  assistLog('sheet returned draft → review');
  await _openReview(context, state, draft);
}

Future<void> _openReview(BuildContext context, AppState state, AssistDraft draft) {
  assistLog('open review products=${draft.products.length} unmatched=${draft.unmatched.length}');
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => AssistReviewPage(state: state, draft: draft)),
  );
}

String _pasteError(AppLocalizations l10n, AssistParseError error) {
  return switch (error) {
    AssistParseError.empty => l10n.assistErrorEmpty,
    AssistParseError.noProducts => l10n.assistErrorNoProducts,
    AssistParseError.nothingToApply => l10n.assistErrorNothing,
  };
}
