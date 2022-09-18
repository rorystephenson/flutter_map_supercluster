import 'dart:math';
import 'dart:ui';

import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

class MapCalculator {
  final FlutterMapState _mapState;
  final Size clusterWidgetSize;
  final AnchorPos? clusterAnchorPos;
  final CustomPoint _boundsPixelPadding;

  MapCalculator({
    required FlutterMapState mapState,
    required this.clusterWidgetSize,
    required this.clusterAnchorPos,
  })  : _mapState = mapState,
        _boundsPixelPadding = CustomPoint(
          clusterWidgetSize.width / 2,
          clusterWidgetSize.height / 2,
        );

  CustomPoint<num> getPixelFromPoint(LatLng point) {
    var pos = _mapState.project(point);
    return pos.multiplyBy(
            _mapState.getZoomScale(_mapState.zoom, _mapState.zoom)) -
        _mapState.pixelOrigin;
  }

  LatLngBounds paddedMapBounds() {
    final bounds = _mapState.pixelBounds;
    return LatLngBounds(
      _mapState.unproject(bounds.topLeft - _boundsPixelPadding),
      _mapState.unproject(bounds.bottomRight + _boundsPixelPadding),
    );
  }

  LatLng clusterPoint(LayerCluster<Marker> cluster) {
    return LatLng(cluster.latitude, cluster.longitude);
  }

  Point<double> removeClusterAnchor(
      CustomPoint pos, LayerCluster<Marker> cluster) {
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
}
