import 'dart:math';

import 'package:flutter_map/plugin_api.dart';

class AnchorUtil {
  static Point<double> removeAnchor(
    Point pos,
    double width,
    double height,
    Anchor anchor,
  ) {
    final x = (pos.x - (width - anchor.left)).toDouble();
    final y = (pos.y - (height - anchor.top)).toDouble();
    return Point(x, y);
  }
}
