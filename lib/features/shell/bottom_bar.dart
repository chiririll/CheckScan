import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';

class BottomBarItem {
  const BottomBarItem({required this.label, required this.icon, required this.activeIcon});

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Two tabs with a raised scan button between them.
class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelect,
    required this.onScan,
  });

  final List<BottomBarItem> items;
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 76,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(top: BorderSide(color: palette.divider)),
              ),
              child: Row(
                children: [
                  _BarTab(item: items[0], active: index == 0, onTap: () => onSelect(0)),
                  const SizedBox(width: 72),
                  _BarTab(item: items[1], active: index == 1, onTap: () => onSelect(1)),
                ],
              ),
            ),
            Positioned(
              top: -22,
              left: 0,
              right: 0,
              child: Center(child: _ScanButton(onTap: onScan)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarTab extends StatelessWidget {
  const _BarTab({required this.item, required this.active, required this.onTap});

  final BottomBarItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = active ? palette.primary : palette.muted;
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: active ? 56 : 32,
              height: 30,
              decoration: BoxDecoration(
                color: active ? palette.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: Icon(
                  active ? item.activeIcon : item.icon,
                  key: ValueKey(active),
                  size: 22,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: color),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return PressScale(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.primary, Color.lerp(palette.primary, Colors.black, 0.28)!],
          ),
          border: Border.all(color: palette.background, width: 4),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(Icons.qr_code_scanner_rounded, color: palette.onPrimary, size: 28),
      ),
    );
  }
}
