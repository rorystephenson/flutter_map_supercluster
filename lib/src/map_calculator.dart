import 'dart:math';
import 'dart:ui';

import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

import 'cluster_data.dart';

class MapCalculator {
  final MapState mapState;
  final AnchorPos? clusterAnchorPos;

  MapCalculator(
    this.mapState, {
    required this.clusterAnchorPos,
  });

  CustomPoint<num> getPixelFromPoint(LatLng point) {
    var pos = mapState.project(point);
    return pos.multiplyBy(mapState.getZoomScale(mapState.zoom, mapState.zoom)) -
        mapState.getPixelOrigin();
  }

  LatLng clusterPoint(Cluster<Marker> cluster) {
    return LatLng(cluster.latitude, cluster.longitude);
  }

  Size clusterSize(Cluster<Marker> cluster) =>
      (cluster.clusterData as ClusterData).visualSize!;

  Point<double> removeClusterAnchor(CustomPoint pos, Cluster<Marker> cluster) {
    final calculatedSize = clusterSize(cluster);
    final anchor = Anchor.forPos(
      clusterAnchorPos,
      calculatedSize.width,
      calculatedSize.height,
    );

    return removeAnchor(
      pos,
      calculatedSize.width,
      calculatedSize.height,
      anchor,
    );
  }

  Point<double> removeAnchor(
      Point pos, double width, double height, Anchor anchor) {
    final x = (pos.x - (width - anchor.left)).toDouble();
    final y = (pos.y - (height - anchor.top)).toDouble();
    return Point(x, y);
  }
}
