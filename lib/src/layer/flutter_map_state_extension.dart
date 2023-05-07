import 'dart:ui';

import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

extension FlutterMapStateExtension on FlutterMapState {
  CustomPoint<num> getPixelOffset(LatLng point) => project(point) - pixelOrigin;

  LatLngBounds paddedMapBounds(Size clusterWidgetSize) {
    final boundsPixelPadding = CustomPoint(
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
