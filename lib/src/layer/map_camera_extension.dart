import 'dart:math';
import 'dart:ui';

import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

extension MapCameraExtension on MapCamera {
  Point<num> getPixelOffset(LatLng point) =>
      project(point) - pixelOrigin.toDoublePoint();

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
