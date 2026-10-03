import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import 'assist/assist_actions.dart';
import 'catalog_nav.dart';
import 'catalog_search_field.dart';
import 'catalog_trail.dart';
import 'tabs/categories_tab.dart';
import 'tabs/products_tab.dart';
import 'tabs/unassigned_tab.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.state, this.initialTab = CatalogTab.unassigned});

  final AppState state;
  final int initialTab;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.state.catalogTab.addListener(_onTabRequest);
    _query.addListener(() => setState(() {}));
  }

  void _onTabRequest() {
    final pending = widget.state.catalogTab.take();
    if (pending != null && pending != _tabs.index) _tabs.animateTo(pending);
  }

  @override
  void dispose() {
    widget.state.catalogTab.removeListener(_onTabRequest);
    _tabs.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = widget.state.catalog;
    return ListenableBuilder(
      listenable: Listenable.merge([_tabs, catalog]),
      builder: (context, _) {
        final onUnassigned = _tabs.index == CatalogTab.unassigned;
        final canAssist = catalog.unassigned.isNotEmpty;
        return Scaffold(
          appBar: CatalogAppBar(
            title: l10n.catalogTitle,
            actions: [
              if (onUnassigned) ...[
                CatalogAction(
                  label: l10n.assistCopyShort,
                  enabled: canAssist,
                  onSelected: () => copyAssistPrompt(context, widget.state),
                ),
                CatalogAction(
                  label: l10n.assistPasteShort,
                  enabled: canAssist,
                  onSelected: () => pasteAssistReply(context, widget.state),
                ),
              ],
            ],
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
          body: Column(
            children: [
              if (_tabs.index != CatalogTab.categories)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: CatalogSearchField(controller: _query, hintText: l10n.catalogSearch),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    UnassignedTab(state: widget.state, query: _query.text),
                    ProductsTab(state: widget.state, query: _query.text),
                    CategoriesTab(state: widget.state),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
