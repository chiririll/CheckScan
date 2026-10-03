import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Centered title + body for empty states.
class CenteredMessage extends StatelessWidget {
  const CenteredMessage({super.key, required this.title, required this.body, this.footer});

  final String title;
  final String body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final footer = this.footer;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: AppText.muted),
            if (footer != null) ...[const SizedBox(height: 12), footer],
          ],
        ),
      ),
    );
  }
}
