import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// [ListTile] on a white outlined card.
class CardTile extends StatelessWidget {
  const CardTile({super.key, required this.title, this.subtitle, this.trailing, this.onTap});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return ListTile(
      tileColor: Colors.white,
      shape: AppShapes.card,
      title: Text(title),
      subtitle: subtitle == null || subtitle.isEmpty ? null : Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Padded list of cards with an 8px gap.
class CardList extends StatelessWidget {
  const CardList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: itemBuilder,
    );
  }
}
