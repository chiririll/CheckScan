import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/catalog/catalog_position.dart';
import '../../core/catalog/category_label.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../widgets/empty_hint.dart';
import 'assign_sheet.dart';
import 'catalog_dialogs.dart';
import 'category_page.dart';
import 'product_page.dart';
import 'unit_labels.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.state, this.initialTab = 0});

  final AppState state;
  final int initialTab;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalogTitle),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: l10n.catalogUnassigned),
            Tab(text: l10n.catalogProducts),
            Tab(text: l10n.catalogCategories),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          return Column(
            children: [
              AnimatedBuilder(
                animation: _tabs,
                builder: (context, child) => _tabs.index < 2 ? child! : const SizedBox.shrink(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _query,
                    decoration: InputDecoration(
                      hintText: l10n.catalogSearch,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _UnassignedTab(state: widget.state, query: _query.text),
                    _ProductsTab(state: widget.state, query: _query.text),
                    _CategoriesTab(state: widget.state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UnassignedTab extends StatelessWidget {
  const _UnassignedTab({required this.state, required this.query});

  final AppState state;
  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = state.catalog.positionCounts(state.receipts);
    final needle = query.trim().toLowerCase();
    final items = [
      for (final position in state.catalog.unassigned)
        if (needle.isEmpty || position.displayName.toLowerCase().contains(needle)) position,
    ]..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    if (state.catalog.unassigned.isEmpty) {
      return EmptyHint(title: l10n.catalogEmptyUnassigned, body: l10n.catalogEmptyUnassignedBody);
    }
    if (items.isEmpty) {
      return EmptyHint(title: l10n.catalogEmptySearch, body: l10n.catalogSearch);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _PositionCard(state: state, position: items[index], count: counts[items[index].id] ?? 0),
    );
  }
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({required this.state, required this.position, required this.count});

  final AppState state;
  final CatalogPosition position;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = formatCatalogUnit(position.unit, position.unitSize, l10n);
    final suggestions = state.catalog.suggestionsFor(position);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE4E4E4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showAssignSheet(context: context, state: state, position: position),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(position.displayName)),
                  Text(l10n.timesCount(count), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(unit, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final other in suggestions.take(2))
                    ActionChip(
                      label: Text(other.displayName, overflow: TextOverflow.ellipsis),
                      onPressed: () => state.catalog.mergePositions(sourceId: position.id, targetId: other.id),
                    ),
                  ActionChip(
                    label: Text(l10n.assignToProduct),
                    onPressed: () => showAssignSheet(context: context, state: state, position: position),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.state, required this.query});

  final AppState state;
  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final needle = query.trim().toLowerCase();
    final items = [
      for (final product in state.catalog.products)
        if (needle.isEmpty || product.name.toLowerCase().contains(needle)) product,
    ];
    if (state.catalog.products.isEmpty) {
      return EmptyHint(title: l10n.catalogEmptyProducts, body: l10n.catalogEmptyProductsBody);
    }
    if (items.isEmpty) {
      return EmptyHint(title: l10n.catalogEmptySearch, body: l10n.catalogSearch);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = items[index];
        final category = product.categoryId == null ? null : state.catalog.categoryById(product.categoryId!);
        return ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE4E4E4)),
          ),
          title: Text(product.name),
          subtitle: category == null ? null : Text(categoryTitle(category, l10n)),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => ProductPage(state: state, productId: product.id)),
          ),
        );
      },
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: state.catalog.categories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final category = state.catalog.categories[index];
              final count = state.catalog.products.where((product) => product.categoryId == category.id).length;
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFE4E4E4)),
                ),
                title: Text(categoryTitle(category, l10n)),
                subtitle: Text(l10n.itemsCount(count)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => CategoryPage(state: state, categoryId: category.id)),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'rename') {
                      final current = categoryTitle(category, l10n);
                      final name = await promptText(
                        context,
                        title: l10n.categoryName,
                        initial: current,
                        confirm: l10n.save,
                      );
                      if (name != null && name != current) await state.catalog.renameCategory(category.id, name);
                    } else if (value == 'delete') {
                      final ok = await confirmAction(
                        context,
                        title: l10n.deleteCategoryTitle,
                        body: l10n.deleteCategoryBody,
                        confirm: l10n.deleteReceipt,
                      );
                      if (ok) await state.catalog.deleteCategory(category.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.deleteReceipt, style: const TextStyle(color: Color(0xFFC62828))),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: FilledButton(
              onPressed: () async {
                final name = await promptText(context, title: l10n.addCategory, confirm: l10n.save);
                if (name != null) await state.catalog.createCategory(name);
              },
              child: Text(l10n.addCategory),
            ),
          ),
        ),
      ],
    );
  }
}
