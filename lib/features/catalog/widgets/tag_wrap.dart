import 'package:flutter/material.dart';

import '../../../core/catalog/model/catalog_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/dialogs.dart';

/// Removable tag chips plus an "add tag" chip that prompts for a name.
class TagWrap extends StatelessWidget {
  const TagWrap({super.key, required this.tags, required this.onAdd, required this.onRemove});

  final List<CatalogTag> tags;
  final Future<void> Function(String name) onAdd;
  final void Function(String tagId) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in tags) InputChip(label: Text(tag.name), onDeleted: () => onRemove(tag.id)),
        ActionChip(
          label: Text(l10n.addTag),
          onPressed: () async {
            final name = await promptText(context, title: l10n.addTag, confirm: l10n.save);
            if (name != null) await onAdd(name);
          },
        ),
      ],
    );
  }
}
