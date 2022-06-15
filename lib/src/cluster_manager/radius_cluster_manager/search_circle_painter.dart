import 'package:flutter/material.dart';

class SearchCirclePainter extends CustomPainter {
  final Offset offset;
  final double pixelRadius;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderWidth;

  SearchCirclePainter({
    required this.pixelRadius,
    required this.offset,
    this.borderWidth,
    this.fillColor,
    this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    if (fillColor != null) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = fillColor!;

      _paintCircle(canvas, offset, pixelRadius, paint);
    }

    if (borderColor != null && borderWidth != null) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = borderColor!
        ..strokeWidth = borderWidth!;

      _paintCircle(
        canvas,
        offset,
        pixelRadius + (borderWidth! / 2),
        paint,
      );
    }
  }

  void _paintCircle(Canvas canvas, Offset offset, double radius, Paint paint) {
    canvas.drawCircle(offset, radius, paint);
  }

  @override
  bool shouldRepaint(SearchCirclePainter oldDelegate) => false;
}
