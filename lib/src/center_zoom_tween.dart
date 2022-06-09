import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

class CenterZoomTween extends Tween<CenterZoom> {
  CenterZoomTween({
    required CenterZoom begin,
    required CenterZoom end,
  }) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  CenterZoom lerp(double t) {
    return CenterZoom(
      center: LatLng(
        lerpDouble(begin!.center.latitude, end!.center.latitude, t)!,
        lerpDouble(begin!.center.longitude, end!.center.longitude, t)!,
      ),
      zoom: lerpDouble(begin!.zoom, end!.zoom, t)!,
    );
  }
}
