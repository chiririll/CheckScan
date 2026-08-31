import 'package:flutter/material.dart';

class ScanFramePainter extends CustomPainter {
  ScanFramePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 20.0;
    final arm = size.shortestSide * 0.16;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    const r = Radius.circular(radius);

    canvas
      ..drawPath(
        Path()
          ..moveTo(0, arm)
          ..lineTo(0, radius)
          ..arcToPoint(const Offset(radius, 0), radius: r)
          ..lineTo(arm, 0),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(w - arm, 0)
          ..lineTo(w - radius, 0)
          ..arcToPoint(Offset(w, radius), radius: r)
          ..lineTo(w, arm),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(w, h - arm)
          ..lineTo(w, h - radius)
          ..arcToPoint(Offset(w - radius, h), radius: r)
          ..lineTo(w - arm, h),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(arm, h)
          ..lineTo(radius, h)
          ..arcToPoint(Offset(0, h - radius), radius: r)
          ..lineTo(0, h - arm),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant ScanFramePainter oldDelegate) => oldDelegate.color != color;
}
