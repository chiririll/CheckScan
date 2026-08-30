import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../history/history_page.dart';
import '../home/home_page.dart';
import '../scan/scan_page.dart';

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
                  border: Border(top: BorderSide(color: Color(0xFFE8E8E8))),
                ),
                child: Row(
                  children: [
                    _Tab(label: l10n.tabHome, active: _tab == 0, onTap: () => setState(() => _tab = 0)),
                    const SizedBox(width: 64),
                    _Tab(label: l10n.tabHistory, active: _tab == 1, onTap: () => setState(() => _tab = 1)),
                  ],
                ),
              ),
              Positioned(
                top: -18,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ScanPage(state: widget.state), fullscreenDialog: true),
                      );
                    },
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
              color: active ? const Color(0xFF1B1B1B) : Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
