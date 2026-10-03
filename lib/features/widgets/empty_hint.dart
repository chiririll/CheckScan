import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'centered_message.dart';

/// Empty state with a bouncing arrow pointing at the bottom bar.
class EmptyHint extends StatefulWidget {
  const EmptyHint({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  State<EmptyHint> createState() => _EmptyHintState();
}

class _EmptyHintState extends State<EmptyHint> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CenteredMessage(
      title: widget.title,
      body: widget.body,
      footer: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.translate(offset: Offset(0, _controller.value * 10), child: child),
        child: CustomPaint(
          size: const Size(32, 168),
          painter: _ArrowPainter(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(Offset(size.width / 2, 4), Offset(size.width / 2, size.height - 20), paint);
    final path = Path()
      ..moveTo(6, size.height - 32)
      ..lineTo(size.width / 2, size.height - 12)
      ..lineTo(size.width - 6, size.height - 32);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) => oldDelegate.color != color;
}
