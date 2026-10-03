import 'package:flutter/material.dart';

import '../../../core/catalog/model/catalog_position.dart';
import '../../../core/util/collections.dart';
import '../../../l10n/app_localizations.dart';
import '../catalog_search_field.dart';

/// Searchable list of [available] positions; resolves to the picked id.
Future<String?> showPositionPicker(BuildContext context, List<CatalogPosition> available) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _PositionPickerSheet(available: available),
  );
}

class _PositionPickerSheet extends StatefulWidget {
  const _PositionPickerSheet({required this.available});

  final List<CatalogPosition> available;

  @override
  State<_PositionPickerSheet> createState() => _PositionPickerSheetState();
}

class _PositionPickerSheetState extends State<_PositionPickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = filterByQuery(widget.available, _query.text, (position) => [position.displayName]);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: 420,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: CatalogSearchField(
                  controller: _query,
                  hintText: l10n.catalogSearch,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final position = items[index];
                    return ListTile(
                      title: Text(position.displayName),
                      onTap: () => Navigator.pop(context, position.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
