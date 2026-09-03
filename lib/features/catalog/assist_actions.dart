import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_state.dart';
import '../../core/catalog/assist_cluster.dart';
import '../../core/catalog/assist_draft.dart';
import '../../core/catalog/assist_parse.dart';
import '../../core/catalog/assist_prompt.dart';
import '../../core/catalog/category_label.dart';
import '../../l10n/app_localizations.dart';
import 'assist_review_page.dart';

Future<void> copyAssistPrompt(BuildContext context, AppState state) async {
  final l10n = AppLocalizations.of(context);
  final batch = nextAssistBatch(state.catalog.unassigned);
  if (batch.isEmpty) return;
  final text = buildAssistPrompt(
    languageName: l10n.appLanguageName,
    categories: assistCategoryHints(state.catalog.categories, (category) => categoryTitle(category, l10n)),
    products: similarProductsFor(batch, state.catalog.products),
    positions: batch,
  );
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.assistCopied)));
}

Future<void> pasteAssistJson(BuildContext context, AppState state) async {
  final l10n = AppLocalizations.of(context);
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final result = parseAssistJson(
    data?.text ?? '',
    AssistParseContext(
      categories: state.catalog.categories,
      products: state.catalog.products,
      positions: state.catalog.positions,
      seedLabels: seedCategoryLabels(l10n),
    ),
  );
  if (!context.mounted) return;
  if (!result.isOk) {
    await _showParseError(context, state, result.error!);
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => AssistReviewPage(state: state, draft: result.draft!)),
  );
}

Future<void> _showParseError(BuildContext context, AppState state, AssistParseError error) async {
  final l10n = AppLocalizations.of(context);
  final message = switch (error) {
    AssistParseError.empty => l10n.assistErrorEmpty,
    AssistParseError.notJson => l10n.assistErrorNotJson,
    AssistParseError.noProducts => l10n.assistErrorNoProducts,
    AssistParseError.nothingToApply => l10n.assistErrorNothing,
  };
  final again = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.assistPasteJson),
      content: Text(message),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.assistPasteJson)),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
      ],
    ),
  );
  if (again == true && context.mounted) await pasteAssistJson(context, state);
}
