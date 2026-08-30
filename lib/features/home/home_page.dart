import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/models/receipt_record.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../settings/settings_page.dart';
import '../widgets/empty_hint.dart';
import 'home_stats.dart';

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
          : _HomeBody(receipts: state.receipts),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody({required this.receipts});

  final List<ReceiptRecord> receipts;

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  late HomePeriod _period;

  @override
  void initState() {
    super.initState();
    _period = HomePeriod.current();
  }

  @override
  Widget build(BuildContext context) {
    final receipts = widget.receipts;
    final currencies = listCurrencies(receipts);
    if (currencies.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return EmptyHint(title: l10n.emptyHomeTitle, body: l10n.emptyHomeBody);
    }
    final multi = currencies.length > 1;
    return DefaultTabController(
      key: ValueKey(currencies.join(',')),
      length: currencies.length,
      child: Column(
        children: [
          _PeriodBar(
            period: _period,
            onPrevious: () => setState(() => _period = _period.previous),
            onNext: _period.isBefore(HomePeriod.current()) ? () => setState(() => _period = _period.next) : null,
          ),
          if (multi)
            TabBar(
              tabs: [for (final currency in currencies) Tab(text: formatCurrencyLabel(currency))],
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
            ),
          Expanded(
            child: multi
                ? TabBarView(
                    children: [
                      for (final currency in currencies)
                        _StatsPane(receipts: receipts, period: _period, currency: currency),
                    ],
                  )
                : _StatsPane(receipts: receipts, period: _period, currency: currencies.first),
          ),
        ],
      ),
    );
  }
}

class _PeriodBar extends StatelessWidget {
  const _PeriodBar({required this.period, required this.onPrevious, required this.onNext});

  final HomePeriod period;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.previousPeriod,
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Text(
              formatMonthYear(period.asDate),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            tooltip: l10n.nextPeriod,
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _StatsPane extends StatelessWidget {
  const _StatsPane({required this.receipts, required this.period, required this.currency});

  final List<ReceiptRecord> receipts;
  final HomePeriod period;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = HomeStats.of(
      receipts,
      period: period,
      currency: currency,
      fallbackMerchant: l10n.receiptTitle,
    );
    if (stats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.emptyPeriodTitle, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              Text(l10n.emptyPeriodBody, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }
    final maxCount = stats.top.isEmpty ? 1 : stats.top.first.count;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: _Metric(value: formatMoney(stats.spent, currency), label: l10n.spent)),
            const SizedBox(width: 12),
            Expanded(child: _Metric(value: '${stats.receiptCount}', label: l10n.receiptCount)),
          ],
        ),
        if (stats.top.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(l10n.mostOften, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...stats.top.map((e) => _Bar(name: e.name, label: l10n.timesCount(e.count), pct: e.count / maxCount)),
        ],
        if (stats.cheaper.isNotEmpty && stats.cheaperKey != null) ...[
          const SizedBox(height: 20),
          Text(l10n.cheaperWhere(stats.cheaperKey!), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...stats.cheaper.map(
            (e) => _Compare(
              store: e.store,
              price: formatMoney(e.price, currency),
              best: e.store == stats.cheaper.first.store,
            ),
          ),
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
