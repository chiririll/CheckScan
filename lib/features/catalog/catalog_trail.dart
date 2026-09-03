import 'package:flutter/material.dart';

class CatalogCrumb {
  const CatalogCrumb({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

class CatalogTrail extends StatelessWidget {
  const CatalogTrail({super.key, required this.crumbs, this.trailing = const []});

  final List<CatalogCrumb> crumbs;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < crumbs.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('›', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                    ),
                  _CrumbText(crumb: crumbs[i], current: i == crumbs.length - 1),
                ],
              ],
            ),
          ),
        ),
        ...trailing,
      ],
    );
  }
}

class _CrumbText extends StatelessWidget {
  const _CrumbText({required this.crumb, required this.current});

  final CatalogCrumb crumb;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final color = current ? const Color(0xFF1B1B1B) : Colors.grey.shade700;
    final child = Text(
      crumb.label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: current ? FontWeight.w600 : FontWeight.w400,
        color: color,
      ),
    );
    if (crumb.onTap == null) return child;
    return InkWell(
      onTap: crumb.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: child,
      ),
    );
  }
}
