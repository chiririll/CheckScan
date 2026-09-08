import 'package:flutter/material.dart';

import '../../theme.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE4E4E4))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        borderRadius: BorderRadius.circular(12),
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
    return Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 13));
  }
}

class HomeMetric extends StatelessWidget {
  const HomeMetric({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}
