import 'package:flutter/material.dart';

import '../../app/theme.dart';

class HomeBlock extends StatelessWidget {
  const HomeBlock({
    super.key,
    required this.title,
    required this.child,
    this.onTap,
  });

  final String title;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(BorderSide(color: context.palette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.title),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

class HomeBlockHint extends StatelessWidget {
  const HomeBlockHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.mutedSmall(context));
  }
}

class HomeMetric extends StatelessWidget {
  const HomeMetric({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(color: palette.primarySoft, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                value,
                key: ValueKey(value),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: palette.primary),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: palette.muted, fontSize: 12)),
        ],
      ),
    );
  }
}
