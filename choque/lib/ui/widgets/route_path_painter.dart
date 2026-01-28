import 'package:flutter/material.dart';
import '../design_system.dart';

/// Custom painter để vẽ route path trên map
class RoutePathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Simulated route path (curved)
    path.moveTo(size.width * 0.3, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.3,
      size.width * 0.7,
      size.height * 0.25,
    );

    canvas.drawPath(path, paint);

    // Dashed future path
    final dashedPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final dashedPath = Path();
    dashedPath.moveTo(size.width * 0.7, size.height * 0.25);
    dashedPath.lineTo(size.width * 0.8, size.height * 0.2);

    canvas.drawPath(dashedPath, dashedPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
