import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

class DisplacedMarker {
<<<<<<< HEAD
  static final anchorPos = AnchorPos.align(AnchorAlign.center);
<<<<<<< HEAD
=======
=======
  static const anchorPos = AnchorPos.align(AnchorAlign.center);
>>>>>>> da17791 (Target flutter_map v6 and fix some bugs around splay clusters when inserting/removing markers.)

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
