import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/catalog/assist/assist_cluster.dart';
import '../../core/catalog/model/catalog_position.dart';
import '../../core/catalog/model/item_unit.dart';
import '../../core/catalog/text/unit_parser.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../labels/category_label.dart';
import '../labels/unit_labels.dart';
import '../widgets/bottom_action.dart';
import '../widgets/navigation.dart';
import '../widgets/unit_dropdown.dart';
import 'catalog_nav.dart';
import 'catalog_trail.dart';
import 'category_picker.dart';
import 'widgets/position_amount.dart';
import 'widgets/position_picker_sheet.dart';

Future<void> openDraftProduct({
  required BuildContext context,
  required AppState state,
  required List<CatalogPosition> positions,
}) {
  return pushPage<void>(
    context,
    DraftProductPage(
      state: state,
      initialPositionIds: [for (final position in positions) position.id],
      initialName: proposedClusterName(positions),
    ),
  );
}

/// New product from a cluster of unassigned positions.
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
  late final _name = TextEditingController(text: widget.initialName);
  late final Set<String> _ids = {...widget.initialPositionIds};
  late ItemUnit? _unit = _guessUnit();
  String? _categoryId;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  ItemUnit? _guessUnit() {
    for (final id in widget.initialPositionIds) {
      final position = widget.state.catalog.positionById(id);
      final parsed = position == null ? null : parseItemUnit(position.displayName);
      if (parsed != null) return parsed.unit;
    }
    return null;
  }

  List<CatalogPosition> _selectedPositions() {
    return [
      for (final id in _ids)
        if (widget.state.catalog.positionById(id) case final position? when position.productId == null) position,
    ];
  }

  List<CatalogPosition> _availablePositions() {
    return [for (final position in widget.state.catalog.unassigned) if (!_ids.contains(position.id)) position];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.state.catalog,
      builder: (context, _) {
        final positions = _selectedPositions();
        final name = _name.text.trim();
        final canSave = !_saving && name.isNotEmpty && positions.isNotEmpty;
        return Scaffold(
          appBar: CatalogAppBar(
            title: name.isEmpty ? l10n.newProduct : name,
            ancestors: [
              CatalogCrumb(label: l10n.catalogTitle, onTap: () => openCatalog(context, widget.state)),
              CatalogCrumb(label: l10n.catalogUnassigned, onTap: () => Navigator.pop(context)),
            ],
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
              UnitDropdownTile(value: _unit, onChanged: (value) => setState(() => _unit = value)),
              const SizedBox(height: 8),
              Text(l10n.positionsSection, style: AppText.title),
              const SizedBox(height: 8),
              for (final position in positions)
                _DraftPositionRow(state: widget.state, position: position, onRemove: () => _remove(position.id)),
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
          bottomNavigationBar: BottomAction(
            label: l10n.draftProductCreate,
            onPressed: canSave ? () => _save(positions) : null,
          ),
        );
      },
    );
  }

  String _categoryLabel(AppLocalizations l10n) {
    final category = _categoryId == null ? null : widget.state.catalog.categoryById(_categoryId!);
    return category == null ? l10n.noCategory : categoryTitle(category, l10n);
  }

  /// Removing a position from a multi-position draft also dismisses it from the cluster.
  void _remove(String positionId) {
    final hasOthers = _ids.any((id) => id != positionId);
    setState(() => _ids.remove(positionId));
    if (hasOthers) widget.state.catalog.dismissClusterItem(positionId);
  }

  Future<void> _pickCategory() async {
    final selected = await pickAssignableCategory(
      context: context,
      catalog: widget.state.catalog,
      currentId: _categoryId,
    );
    if (selected == null) return;
    setState(() => _categoryId = selected.isEmpty ? null : selected);
  }

  Future<void> _addPosition() async {
    final picked = await showPositionPicker(context, _availablePositions());
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
  const _DraftPositionRow({required this.state, required this.position, required this.onRemove});

  final AppState state;
  final CatalogPosition position;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meta = formatPositionPack(position, null, l10n);
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: AppShapes.card,
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
