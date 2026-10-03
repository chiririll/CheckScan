import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/state/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../history/history_page.dart';
import '../home/home_page.dart';
import '../scan/scan_page.dart';
import '../widgets/navigation.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});

  final AppState state;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  Widget _tabButton(String label, int index) {
    return _Tab(label: label, active: _tab == index, onTap: () => setState(() => _tab = index));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) => IndexedStack(
          index: _tab,
          children: [
            HomePage(state: widget.state),
            HistoryPage(state: widget.state),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    _tabButton(l10n.tabHome, 0),
                    const SizedBox(width: 64),
                    _tabButton(l10n.tabHistory, 1),
                  ],
                ),
              ),
              Positioned(
                top: -18,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => pushPage<void>(context, ScanPage(state: widget.state), fullscreenDialog: true),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.text : Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
