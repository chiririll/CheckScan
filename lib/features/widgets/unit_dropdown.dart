import 'package:flutter/material.dart';

import '../../core/catalog/model/item_unit.dart';
import '../../l10n/app_localizations.dart';
import '../labels/unit_labels.dart';

/// "Unit" row with a dropdown of every [ItemUnit] plus "none".
class UnitDropdownTile extends StatelessWidget {
  const UnitDropdownTile({super.key, required this.value, required this.onChanged});

  final ItemUnit? value;
  final ValueChanged<ItemUnit?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.unitLabel),
      trailing: DropdownButton<ItemUnit?>(
        value: value,
        underline: const SizedBox.shrink(),
        items: [
          DropdownMenuItem(value: null, child: Text(l10n.unitNone)),
          for (final item in ItemUnit.values) DropdownMenuItem(value: item, child: Text(unitLabel(item, l10n))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
