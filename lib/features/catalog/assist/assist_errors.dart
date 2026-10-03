import '../../../core/catalog/assist/assist_draft.dart';
import '../../../l10n/app_localizations.dart';

String assistErrorText(AppLocalizations l10n, AssistParseError error) {
  return switch (error) {
    AssistParseError.empty => l10n.assistErrorEmpty,
    AssistParseError.noProducts => l10n.assistErrorNoProducts,
    AssistParseError.nothingToApply => l10n.assistErrorNothing,
  };
}
