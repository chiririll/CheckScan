import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../history/history_page.dart';
import '../home/home_page.dart';
import '../scan/scan_page.dart';
import '../widgets/navigation.dart';
import 'bottom_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});

  final AppState state;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) => IndexedStack(
          index: _tab,
          children: [
            TabFade(active: _tab == 0, child: HomePage(state: widget.state)),
            TabFade(active: _tab == 1, child: HistoryPage(state: widget.state)),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        index: _tab,
        onSelect: (i) => setState(() => _tab = i),
        onScan: () => pushPage<void>(context, ScanPage(state: widget.state), fullscreenDialog: true),
        items: [
          BottomBarItem(label: l10n.tabHome, icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
          BottomBarItem(label: l10n.tabHistory, icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long),
        ],
      ),
    );
  }
}
