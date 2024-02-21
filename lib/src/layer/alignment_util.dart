import 'dart:math';

import 'package:flutter/material.dart';

class AlignmentUtil {
  static Point<double> applyAlignment(
    Point pos,
    double width,
    double height,
    Alignment alignment,
  ) {
    final x = (pos.x - (width / 2) + ((width / 2) * alignment.x)).toDouble();
    final y = (pos.y - (height / 2) + ((height / 2) * alignment.y)).toDouble();
    return Point(x, y);
  }
}
