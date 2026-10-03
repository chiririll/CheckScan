import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/format/format.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../merchant/merchants_page.dart';
import '../settings/settings_page.dart';
import '../widgets/centered_message.dart';
import '../widgets/empty_hint.dart';
import '../widgets/navigation.dart';
import 'home_block.dart';
import 'home_dashboard.dart';
import 'home_period.dart';

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
            onPressed: () => pushPage<void>(context, SettingsPage(state: state)),
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
              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500),
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
      merchants: state.merchants.all,
      period: period,
      currency: currency,
    );
    if (dash.isEmpty) return CenteredMessage(title: l10n.emptyPeriodTitle, body: l10n.emptyPeriodBody);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: HomeMetric(value: formatMoney(dash.spent.abs(), scale: dash.spentScale, currency: currency, plus: dash.spent < 0), label: l10n.spent)),
            const SizedBox(width: 12),
            Expanded(child: HomeMetric(value: '${dash.receiptCount}', label: l10n.receiptCount)),
          ],
        ),
        const SizedBox(height: 16),
        HomeBlock(
          title: l10n.merchantsBlock,
          onTap: () => pushPage<void>(context, MerchantsPage(state: state)),
          child: dash.merchants.isEmpty
              ? HomeBlockHint(l10n.merchantsEmptyBody)
              : Text(l10n.merchantsWithoutNetwork(dash.merchants.withoutNetwork)),
        ),
      ],
    );
  }
}
