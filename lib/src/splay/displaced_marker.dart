import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DisplacedMarker {
  static const alignment = Alignment.center;

  final Marker marker;
  final LatLng displacedPoint;

  const DisplacedMarker({
    required this.marker,
    required this.displacedPoint,
  });

  LatLng get originalPoint => marker.point;

  static const AlignmentGeometry rotateAlignment = Alignment.center;
}
