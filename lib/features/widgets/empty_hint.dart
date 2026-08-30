import 'package:flutter/material.dart';

import '../../theme.dart';

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(widget.body, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _controller.value * 10),
                  child: child,
                );
              },
              child: CustomPaint(
                size: const Size(32, 168),
                painter: _ArrowPainter(color: AppColors.primary),
              ),
            ),
          ],
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
