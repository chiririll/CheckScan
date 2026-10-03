import 'package:flutter/material.dart';

/// Full-width primary button pinned above the system inset.
class BottomAction extends StatelessWidget {
  const BottomAction({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(onPressed: onPressed, child: Text(label)),
      ),
    );
  }
}
