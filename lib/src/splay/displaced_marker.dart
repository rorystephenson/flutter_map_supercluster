import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

class DisplacedMarker implements Marker {
  static const pi2 = pi * 2;
  static const circleStartAngle = 0;

  final Marker marker;
  final LatLng _pointOverride;

  DisplacedMarker({
    required this.marker,
    required LatLng pointOverride,
  }) : _pointOverride = pointOverride;

  LatLng get originalPoint => marker.point;

  @override
  LatLng get point => _pointOverride;

  // Force a center aligned marker to prevent weird positioning when spreading.
  @override
  AlignmentGeometry? get rotateAlignment => Alignment.center;

  // Force no rotateOrigin to prevent weird positioning when spreading.
  @override
  Offset? get rotateOrigin => null;

  // Force a displaced marker anchor to always be center as any other anchor
  // makes the spread markers look strange.
  @override
  Anchor get anchor => Anchor.forPos(
        AnchorPos.align(AnchorAlign.center),
        width,
        height,
      );

  @override
  operator ==(Object other) {
    if (other is DisplacedMarker) return other.marker == marker;

    return other == marker;
  }

  // This ensures that the popup plugin considers this marker equal to its
  // original marker.
  @override
  int get hashCode => marker.hashCode;

  ///////////////////////////////////////////////////////////////
  /// The remaining methods just proxy to the container Marker //
  ///////////////////////////////////////////////////////////////

  @override
  Key? get key => marker.key;

  @override
  WidgetBuilder get builder => marker.builder;

  @override
  double get height => marker.height;

  @override
  bool? get rotate => marker.rotate;

  @override
  double get width => marker.width;
}
