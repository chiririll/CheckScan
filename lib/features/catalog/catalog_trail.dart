import 'package:flutter/material.dart';

class CatalogCrumb {
  const CatalogCrumb({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

class CatalogTrail extends StatelessWidget {
  const CatalogTrail({super.key, required this.crumbs});

  final List<CatalogCrumb> crumbs;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < crumbs.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('›', style: TextStyle(color: Colors.grey.shade600)),
              ),
            _CrumbText(crumb: crumbs[i]),
          ],
        ],
      ),
    );
  }
}

class _CrumbText extends StatelessWidget {
  const _CrumbText({required this.crumb});

  final CatalogCrumb crumb;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium;
    if (crumb.onTap == null) {
      return Text(crumb.label, style: style?.copyWith(fontWeight: FontWeight.w600));
    }
    return InkWell(
      onTap: crumb.onTap,
      child: Text(crumb.label, style: style?.copyWith(color: Colors.grey.shade800)),
    );
  }
}
