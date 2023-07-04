import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

class DisplacedMarker {
  static final anchorPos = AnchorPos.align(AnchorAlign.center);
<<<<<<< HEAD
=======

>>>>>>> 9275ff8 (v5 WIP)
  final Marker marker;
  final LatLng displacedPoint;

  const DisplacedMarker({
    required this.marker,
    required this.displacedPoint,
  });

  LatLng get originalPoint => marker.point;

  static const AlignmentGeometry rotateAlignment = Alignment.center;

  Anchor get anchor => Anchor.fromPos(
        anchorPos,
        marker.width,
        marker.height,
      );
}
