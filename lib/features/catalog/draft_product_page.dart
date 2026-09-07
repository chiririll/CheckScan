import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/catalog/assist_cluster.dart';
import '../../core/catalog/catalog_position.dart';
import '../../core/catalog/category_label.dart';
import '../../core/catalog/item_unit.dart';
import '../../core/catalog/unit_parser.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import 'catalog_dialogs.dart';
import 'catalog_nav.dart';
import 'catalog_trail.dart';
import 'unit_labels.dart';

Future<void> openDraftProduct({
  required BuildContext context,
  required AppState state,
  required List<CatalogPosition> positions,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DraftProductPage(
        state: state,
        initialPositionIds: [for (final position in positions) position.id],
        initialName: proposedClusterName(positions),
      ),
    ),
  );
}

class DraftProductPage extends StatefulWidget {
  const DraftProductPage({
    super.key,
    required this.state,
    required this.initialPositionIds,
    required this.initialName,
  });

  final AppState state;
  final List<String> initialPositionIds;
  final String initialName;

  @override
  State<DraftProductPage> createState() => _DraftProductPageState();
}

class _DraftProductPageState extends State<DraftProductPage> {
  late final TextEditingController _name;
  late final Set<String> _ids = {...widget.initialPositionIds};
  String? _categoryId;
  ItemUnit? _unit;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _unit = _guessUnit();
    _name.addListener(() => setState(() {}));
  }

  ItemUnit? _guessUnit() {
    for (final id in widget.initialPositionIds) {
      final position = widget.state.catalog.positionById(id);
      if (position == null) continue;
      final parsed = parseItemUnit(position.displayName);
      if (parsed != null) return parsed.unit;
    }
    return null;
  }

  List<CatalogPosition> _selectedPositions() {
    return [
      for (final id in _ids)
        if (widget.state.catalog.positionById(id) case final position?
            when position.productId == null)
          position,
    ];
  }

  List<CatalogPosition> _availablePositions() {
    return [
      for (final position in widget.state.catalog.unassigned)
        if (!_ids.contains(position.id)) position,
    ];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.state.catalog,
      builder: (context, _) {
        final positions = _selectedPositions();
        final canSave = !_saving && _name.text.trim().isNotEmpty && positions.isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: CatalogTrail(
              crumbs: [
                CatalogCrumb(label: l10n.catalogTitle, onTap: () => openCatalog(context, widget.state)),
                CatalogCrumb(label: l10n.catalogUnassigned, onTap: () => Navigator.pop(context)),
                CatalogCrumb(label: _name.text.trim().isEmpty ? l10n.newProduct : _name.text.trim()),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.productName, border: const OutlineInputBorder()),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.productCategory),
                subtitle: Text(_categoryLabel(l10n)),
                onTap: _pickCategory,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.unitLabel),
                trailing: DropdownButton<ItemUnit?>(
                  value: _unit,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.unitNone)),
                    for (final item in ItemUnit.values)
                      DropdownMenuItem(value: item, child: Text(unitLabel(item, l10n))),
                  ],
                  onChanged: (value) => setState(() => _unit = value),
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.positionsSection, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              for (final position in positions)
                _DraftPositionRow(
                  state: widget.state,
                  position: position,
                  onRemove: () => setState(() => _ids.remove(position.id)),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _availablePositions().isEmpty ? null : _addPosition,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addPosition),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  onPressed: canSave ? () => _save(positions) : null,
                  child: Text(l10n.draftProductCreate),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _categoryLabel(AppLocalizations l10n) {
    if (_categoryId == null) return l10n.noCategory;
    final category = widget.state.catalog.categoryById(_categoryId!);
    if (category == null) return l10n.noCategory;
    return categoryTitle(category, l10n);
  }

  Future<void> _pickCategory() async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(l10n.noCategory), onTap: () => Navigator.pop(context, '')),
            for (final category in widget.state.catalog.categories)
              ListTile(
                title: Text(categoryTitle(category, l10n)),
                selected: category.id == _categoryId,
                onTap: () => Navigator.pop(context, category.id),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    setState(() => _categoryId = selected.isEmpty ? null : selected);
  }

  Future<void> _addPosition() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddPositionSheet(available: _availablePositions()),
    );
    if (picked == null) return;
    setState(() => _ids.add(picked));
  }

  Future<void> _save(List<CatalogPosition> positions) async {
    setState(() => _saving = true);
    try {
      await widget.state.catalog.createProductWithPositions(
        name: _name.text.trim(),
        categoryId: _categoryId,
        unit: _unit,
        positionIds: [for (final position in positions) position.id],
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DraftPositionRow extends StatelessWidget {
  const _DraftPositionRow({
    required this.state,
    required this.position,
    required this.onRemove,
  });

  final AppState state;
  final CatalogPosition position;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meta = formatPositionMeta(position, null, l10n);
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE4E4E4)),
      ),
      child: ListTile(
        title: Text(position.displayName),
        subtitle: meta.isEmpty ? null : Text(meta, style: const TextStyle(color: AppColors.primary)),
        trailing: IconButton(tooltip: l10n.detachPosition, onPressed: onRemove, icon: const Icon(Icons.close)),
        onTap: () => editPositionAmount(
          context: context,
          catalog: state.catalog,
          positionId: position.id,
          current: position.unitSize,
        ),
      ),
    );
  }
}

class _AddPositionSheet extends StatefulWidget {
  const _AddPositionSheet({required this.available});

  final List<CatalogPosition> available;

  @override
  State<_AddPositionSheet> createState() => _AddPositionSheetState();
}

class _AddPositionSheetState extends State<_AddPositionSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final needle = _query.text.trim().toLowerCase();
    final items = [
      for (final position in widget.available)
        if (needle.isEmpty || position.displayName.toLowerCase().contains(needle)) position,
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: 420,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _query,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.catalogSearch,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
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
