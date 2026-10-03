import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/catalog/assist/assist_cluster.dart';
import '../../../core/state/app_state.dart';
import '../../../core/util/collections.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/card_tile.dart';
import '../../widgets/empty_hint.dart';
import '../draft_product_page.dart';

class UnassignedTab extends StatelessWidget {
  const UnassignedTab({super.key, required this.state, required this.query});

  final AppState state;
  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.catalog.unassigned.isEmpty) {
      return EmptyHint(title: l10n.catalogEmptyUnassigned, body: l10n.catalogEmptyUnassignedBody);
    }
    final clusters = filterByQuery(
      state.catalog.unassignedClusters,
      query,
      (cluster) => [cluster.name, for (final position in cluster.positions) position.displayName],
    );
    if (clusters.isEmpty) {
      return EmptyHint(title: l10n.catalogEmptySearch, body: l10n.catalogSearch);
    }
    return CardList(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: clusters.length,
      itemBuilder: (context, index) => _ClusterCard(state: state, cluster: clusters[index]),
    );
  }
}

class _ClusterCard extends StatelessWidget {
  const _ClusterCard({required this.state, required this.cluster});

  final AppState state;
  final UnassignedCluster cluster;

  void _open(BuildContext context) => openDraftProduct(context: context, state: state, positions: cluster.positions);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dismissible = cluster.positions.length > 1;
    return Material(
      color: Colors.white,
      shape: AppShapes.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row(
              onTap: () => _open(context),
              dismissKey: const ValueKey<String>('dismiss-cluster'),
              onDismiss: dismissible
                  ? () => state.catalog.dismissCluster(cluster.positions.map((item) => item.id))
                  : null,
              iconSize: 20,
              child: Text(cluster.name, style: AppText.title),
            ),
            for (final position in cluster.preview)
              _Row(
                onTap: () => _open(context),
                dismissKey: ValueKey<String>('dismiss-item-${position.id}'),
                onDismiss: dismissible ? () => state.catalog.dismissClusterItem(position.id) : null,
                iconSize: 18,
                child: Text('• ${position.displayName}'),
              ),
            if (cluster.hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 8),
                child: InkWell(
                  onTap: () => _open(context),
                  child: Text(l10n.clusterAndMore(cluster.hiddenCount), style: AppText.mutedSmall),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.child,
    required this.onTap,
    required this.dismissKey,
    required this.onDismiss,
    required this.iconSize,
  });

  final Widget child;
  final VoidCallback onTap;
  final Key dismissKey;
  final VoidCallback? onDismiss;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: InkWell(onTap: onTap, child: child)),
        if (onDismiss != null)
          IconButton(
            key: dismissKey,
            tooltip: AppLocalizations.of(context).dismissSuggestion,
            onPressed: onDismiss,
            icon: Icon(Icons.close, size: iconSize),
          ),
      ],
    );
  }
}
