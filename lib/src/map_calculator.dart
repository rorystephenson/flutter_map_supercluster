import 'dart:math';
import 'dart:ui';

import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

class MapCalculator {
  final MapState mapState;
  final Size clusterWidgetSize;
  final AnchorPos? clusterAnchorPos;
  final CustomPoint _boundsPixelPadding;

  MapCalculator({
    required this.mapState,
    required this.clusterWidgetSize,
    required this.clusterAnchorPos,
  }) : _boundsPixelPadding = CustomPoint(
          clusterWidgetSize.width / 2,
          clusterWidgetSize.height / 2,
        );

  CustomPoint<num> getPixelFromPoint(LatLng point) {
    final pos = mapState.project(point);
    return pos.multiplyBy(mapState.getZoomScale(mapState.zoom, mapState.zoom)) -
        mapState.getPixelOrigin();
  }

  LatLngBounds paddedMapBounds() {
    final bounds = mapState.pixelBounds;
    return LatLngBounds(
      mapState.unproject(bounds.topLeft - _boundsPixelPadding),
      mapState.unproject(bounds.bottomRight + _boundsPixelPadding),
    );
  }

  LatLng clusterPoint(Cluster<Marker> cluster) {
    return LatLng(cluster.latitude, cluster.longitude);
  }

  Point<double> removeClusterAnchor(CustomPoint pos, Cluster<Marker> cluster) {
    final anchor = Anchor.forPos(
      clusterAnchorPos,
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

  Point<double> removeAnchor(
      Point pos, double width, double height, Anchor anchor) {
    final x = (pos.x - (width - anchor.left)).toDouble();
    final y = (pos.y - (height - anchor.top)).toDouble();
    return Point(x, y);
  }

  CustomPoint project(LatLng latLng, {double? zoom}) =>
      mapState.project(latLng, zoom);
}
