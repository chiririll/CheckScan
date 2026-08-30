import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/models/receipt_record.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../settings/settings_page.dart';
import '../widgets/empty_hint.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
        ],
      ),
      body: state.receipts.isEmpty
          ? EmptyHint(title: l10n.emptyHomeTitle, body: l10n.emptyHomeBody)
          : _Stats(receipts: state.receipts),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.receipts});

  final List<ReceiptRecord> receipts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final month = receipts.where((r) {
      final d = r.issuedAt ?? r.scannedAt;
      return d.year == now.year && d.month == now.month;
    }).toList();
    final spent = month.fold<double>(0, (sum, r) => sum + r.grandTotal);
    final counts = <String, int>{};
    final prices = <String, Map<String, double>>{};
    for (final record in receipts) {
      for (final item in record.receipt.items) {
        counts[item.description] = (counts[item.description] ?? 0) + 1;
        final store = record.merchantName ??
            (record.providerLabel.isNotEmpty ? record.providerLabel : l10n.receiptTitle);
        final byStore = prices.putIfAbsent(item.description, () => {});
        final current = byStore[store];
        if (current == null || item.unitPrice < current) {
          byStore[store] = item.unitPrice;
        }
      }
    }
    final top = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = top.isEmpty ? 1 : top.first.value;
    final cheaperKey = top.isNotEmpty ? top.first.key : null;
    final cheaper = <MapEntry<String, double>>[];
    if (cheaperKey != null) {
      cheaper.addAll(prices[cheaperKey]?.entries ?? const {});
      cheaper.sort((a, b) => a.value.compareTo(b.value));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(formatDayShort(DateTime(now.year, now.month)), style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _Metric(value: formatMoney(spent), label: l10n.spent)),
            const SizedBox(width: 12),
            Expanded(child: _Metric(value: '${month.length}', label: l10n.receiptCount)),
          ],
        ),
        if (top.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(l10n.mostOften, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...top.take(3).map((e) => _Bar(name: e.key, label: l10n.timesCount(e.value), pct: e.value / maxCount)),
        ],
        if (cheaper.isNotEmpty && cheaperKey != null) ...[
          const SizedBox(height: 20),
          Text(l10n.cheaperWhere(cheaperKey), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...cheaper.map((e) => _Compare(store: e.key, price: formatMoney(e.value), best: e.key == cheaper.first.key)),
        ],
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.name, required this.label, required this.pct});
  final String name;
  final String label;
  final double pct;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(name)),
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct.clamp(0.05, 1),
              minHeight: 6,
              color: AppColors.primary,
              backgroundColor: const Color(0xFFE4EEEC),
            ),
          ),
        ],
      ),
    );
  }
}

class _Compare extends StatelessWidget {
  const _Compare({required this.store, required this.price, required this.best});
  final String store;
  final String price;
  final bool best;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: best ? const Color(0xFFE4EEEC) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(child: Text(store, style: TextStyle(fontWeight: best ? FontWeight.w600 : FontWeight.w400))),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
