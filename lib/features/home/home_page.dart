import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../catalog/catalog_nav.dart';
import '../catalog/catalog_page.dart';
import '../catalog/unit_labels.dart';
import '../merchant/merchants_page.dart';
import '../settings/settings_page.dart';
import '../widgets/empty_hint.dart';
import 'frequent_page.dart';
import 'home_block.dart';
import 'home_dashboard.dart';
import 'home_period.dart';
import 'prices_page.dart';
import 'waste_page.dart';

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
            tooltip: l10n.catalogTitle,
            icon: const Icon(Icons.category_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: catalogRouteName),
                builder: (_) => CatalogPage(state: state),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsPage(state: state))),
          ),
        ],
      ),
      body: state.receipts.isEmpty
          ? EmptyHint(title: l10n.emptyHomeTitle, body: l10n.emptyHomeBody)
          : _HomeBody(state: state),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody({required this.state});

  final AppState state;

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
    final receipts = widget.state.receipts;
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
                        _DashboardPane(state: widget.state, period: _period, currency: currency),
                    ],
                  )
                : _DashboardPane(state: widget.state, period: _period, currency: currencies.first),
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

class _DashboardPane extends StatelessWidget {
  const _DashboardPane({required this.state, required this.period, required this.currency});

  final AppState state;
  final HomePeriod period;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dash = HomeDashboard.of(
      receipts: state.receipts,
      purchases: state.catalog.purchases,
      products: state.catalog.products,
      categories: state.catalog.categories,
      positions: state.catalog.positions,
      merchants: state.merchantList,
      resolver: state.catalog.resolver,
      period: period,
      currency: currency,
      fallbackMerchant: l10n.receiptTitle,
    );
    if (dash.isEmpty) {
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: HomeMetric(value: formatMoney(dash.spent, currency), label: l10n.spent)),
            const SizedBox(width: 12),
            Expanded(child: HomeMetric(value: '${dash.receiptCount}', label: l10n.receiptCount)),
          ],
        ),
        const SizedBox(height: 16),
        HomeBlock(
          title: l10n.pricesBlock,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => PricesPage(state: state, rows: dash.priceRows, currency: currency)),
          ),
          child: dash.prices == null
              ? HomeBlockHint(l10n.pricesEmptyBody)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dash.prices!.productName),
                    const SizedBox(height: 2),
                    Text(
                      formatUnitPrice(dash.prices!.perUnit, dash.prices!.unit, currency, l10n),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(l10n.cheaperAt(dash.prices!.networkName), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        HomeBlock(
          title: l10n.wasteBlock,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WastePage(state: state, leaves: dash.wasteLeaves, tags: dash.wasteTags, currency: currency),
            ),
          ),
          child: dash.wasteTotal <= 0
              ? HomeBlockHint(l10n.wasteEmptyBody)
              : Text(formatMoney(dash.wasteTotal, currency), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        HomeBlock(
          title: l10n.frequentBlock,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => FrequentPage(state: state, items: dash.frequent)),
          ),
          child: dash.frequent.isEmpty
              ? HomeBlockHint(l10n.frequentEmptyBody)
              : Column(
                  children: [
                    for (final item in dash.frequent.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(item.name)),
                            Text(l10n.timesCount(item.count), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        HomeBlock(
          title: l10n.merchantsBlock,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => MerchantsPage(state: state)),
          ),
          child: dash.merchants.isEmpty
              ? HomeBlockHint(l10n.merchantsEmptyBody)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.merchantsWithoutNetwork(dash.merchants.withoutNetwork)),
                    Text(l10n.merchantsIgnorePolicy(dash.merchants.ignoreCount), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
        ),
      ],
    );
  }
}
