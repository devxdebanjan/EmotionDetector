import 'package:flutter/material.dart';

class FaceGuidePainter extends CustomPainter {
  final Color color;
  FaceGuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    paint.strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final ovalWidth = size.width * 0.5;
    final ovalHeight = size.height * 0.62;
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: ovalWidth,
      height: ovalHeight,
    );

    const int dashCount = 40;
    const double gapFraction = 0.35;
    final path = Path();
    path.addOval(rect);
    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;
    final segmentLength = totalLength / dashCount;
    final dashLength = segmentLength * (1.0 - gapFraction);

    for (int i = 0; i < dashCount; i++) {
      final start = i * segmentLength;
      final dashPath = metrics.extractPath(start, start + dashLength);
      canvas.drawPath(dashPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FaceGuidePainter oldDelegate) =>
      oldDelegate.color != color;
}
