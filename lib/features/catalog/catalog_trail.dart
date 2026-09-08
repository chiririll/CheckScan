import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class CatalogCrumb {
  const CatalogCrumb({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

class CatalogTrail extends StatelessWidget {
  const CatalogTrail({super.key, required this.crumbs});

  final List<CatalogCrumb> crumbs;

  @override
  Widget build(BuildContext context) {
    if (crumbs.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final current = crumbs.last;
    final ancestors = crumbs.length <= 1 ? const <CatalogCrumb>[] : crumbs.sublist(0, crumbs.length - 1);
    return Row(
      children: [
        if (ancestors.isNotEmpty)
          PopupMenuButton<int>(
            tooltip: l10n.catalogAncestors,
            padding: EdgeInsets.zero,
            onSelected: (index) => ancestors[index].onTap?.call(),
            itemBuilder: (context) => [
              for (var i = 0; i < ancestors.length; i++)
                PopupMenuItem(
                  value: i,
                  enabled: ancestors[i].onTap != null,
                  child: Text(ancestors[i].label),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.more_horiz, color: Colors.grey.shade700),
            ),
          ),
        Expanded(
          child: Text(
            current.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
