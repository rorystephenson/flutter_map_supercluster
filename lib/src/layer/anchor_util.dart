import 'dart:math';
import 'dart:ui';

import 'package:flutter_map/plugin_api.dart';
import 'package:supercluster/supercluster.dart';

class AnchorUtil {
  static Point<double> removeClusterAnchor(
    CustomPoint pos,
    LayerCluster<Marker> cluster,
    AnchorPos? clusterAnchorPos,
    Size clusterWidgetSize,
  ) {
    final anchor = Anchor.fromPos(
      clusterAnchorPos ?? AnchorPos.defaultAnchorPos,
      clusterWidgetSize.width,
      clusterWidgetSize.height,
    );

    return removeAnchor(
      pos,
      clusterWidgetSize.width,
      clusterWidgetSize.height,
      anchor,
    );
  }

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
