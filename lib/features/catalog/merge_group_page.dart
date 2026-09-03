import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/catalog/catalog_position.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import 'catalog_nav.dart';
import 'catalog_trail.dart';
import 'unit_labels.dart';

Future<void> openMergeGroup({
  required BuildContext context,
  required AppState state,
  required CatalogPosition position,
}) async {
  final peers = state.catalog.suggestionsFor(position);
  if (peers.isEmpty) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MergeGroupPage(state: state, target: position, peers: peers),
    ),
  );
}

class MergeGroupPage extends StatefulWidget {
  const MergeGroupPage({super.key, required this.state, required this.target, required this.peers});

  final AppState state;
  final CatalogPosition target;
  final List<CatalogPosition> peers;

  @override
  State<MergeGroupPage> createState() => _MergeGroupPageState();
}

class _MergeGroupPageState extends State<MergeGroupPage> {
  late final Set<String> _kept = {for (final peer in widget.peers) peer.id};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final target = widget.target;
    final peers = [for (final peer in widget.peers) if (_kept.contains(peer.id)) peer];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: CatalogTrail(
          crumbs: [
            CatalogCrumb(label: l10n.catalogTitle, onTap: () => openCatalog(context, widget.state)),
            CatalogCrumb(label: l10n.catalogUnassigned, onTap: () => Navigator.pop(context)),
            CatalogCrumb(label: l10n.mergeGroup),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(l10n.mergeGroupBody, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          _PositionRow(position: target, l10n: l10n, pinned: true),
          for (final peer in peers)
            _PositionRow(
              position: peer,
              l10n: l10n,
              onDrop: () => setState(() => _kept.remove(peer.id)),
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
              onPressed: peers.isEmpty
                  ? null
                  : () async {
                      await widget.state.catalog.mergeGroup(
                        targetId: target.id,
                        sourceIds: [for (final peer in peers) peer.id],
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
              child: Text(l10n.mergeGroupConfirm),
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionRow extends StatelessWidget {
  const _PositionRow({required this.position, required this.l10n, this.pinned = false, this.onDrop});

  final CatalogPosition position;
  final AppLocalizations l10n;
  final bool pinned;
  final VoidCallback? onDrop;

  @override
  Widget build(BuildContext context) {
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
        trailing: pinned
            ? null
            : IconButton(tooltip: l10n.deleteReceipt, onPressed: onDrop, icon: const Icon(Icons.close)),
      ),
    );
  }
}
