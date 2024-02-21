import 'dart:math';
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

extension FlutterMapStateExtension on FlutterMapState {
  Point<num> getPixelOffset(LatLng point) => project(point) - pixelOrigin;

  LatLngBounds paddedMapBounds(Size clusterWidgetSize) {
    final boundsPixelPadding = Point(
      clusterWidgetSize.width / 2,
      clusterWidgetSize.height / 2,
    );
    final bounds = pixelBounds;
    return LatLngBounds(
      unproject(bounds.topLeft - boundsPixelPadding),
      unproject(bounds.bottomRight + boundsPixelPadding),
    );
  }
}
