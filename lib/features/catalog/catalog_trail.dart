import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class CatalogCrumb {
  const CatalogCrumb({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

class CatalogAction {
  const CatalogAction({
    required this.label,
    required this.onSelected,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onSelected;
  final bool destructive;
  final bool enabled;
}

/// App bar: current name as title, one overflow with ancestors and page actions.
class CatalogAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CatalogAppBar({
    super.key,
    required this.title,
    this.ancestors = const [],
    this.actions = const [],
    this.bottom,
  });

  final String title;
  final List<CatalogCrumb> ancestors;
  final List<CatalogAction> actions;
  final PreferredSizeWidget? bottom;

  bool get _hasMenu => ancestors.isNotEmpty || actions.isNotEmpty;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        if (_hasMenu) CatalogOverflowMenu(ancestors: ancestors, actions: actions),
      ],
      bottom: bottom,
    );
  }
}

class CatalogOverflowMenu extends StatelessWidget {
  const CatalogOverflowMenu({super.key, this.ancestors = const [], this.actions = const []});

  final List<CatalogCrumb> ancestors;
  final List<CatalogAction> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_CatalogMenuChoice>(
      tooltip: l10n.catalogMore,
      icon: const Icon(Icons.more_vert),
      onSelected: (choice) {
        if (choice.actionIndex != null) {
          actions[choice.actionIndex!].onSelected();
        } else if (choice.ancestorIndex != null) {
          ancestors[choice.ancestorIndex!].onTap?.call();
        }
      },
      itemBuilder: (context) => [
        for (var i = 0; i < ancestors.length; i++)
          PopupMenuItem(
            value: _CatalogMenuChoice.ancestor(i),
            enabled: ancestors[i].onTap != null,
            child: Text(ancestors[i].label),
          ),
        if (ancestors.isNotEmpty && actions.isNotEmpty) const PopupMenuDivider(),
        for (var i = 0; i < actions.length; i++)
          PopupMenuItem(
            value: _CatalogMenuChoice.action(i),
            enabled: actions[i].enabled,
            child: Text(
              actions[i].label,
              style: actions[i].destructive ? const TextStyle(color: Color(0xFFC62828)) : null,
            ),
          ),
      ],
    );
  }
}

class _CatalogMenuChoice {
  const _CatalogMenuChoice._({this.ancestorIndex, this.actionIndex});

  const _CatalogMenuChoice.ancestor(int index) : this._(ancestorIndex: index);

  const _CatalogMenuChoice.action(int index) : this._(actionIndex: index);

  final int? ancestorIndex;
  final int? actionIndex;
}
