import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/splay/displaced_marker.dart';

/// A [Marker] which has been displaced from its original position.
class DisplacedMarkerOffset {
  final DisplacedMarker displacedMarker;
  final CustomPoint displacedOffset;
  final CustomPoint originalOffset;

  const DisplacedMarkerOffset({
    required this.displacedMarker,
    required this.displacedOffset,
    required this.originalOffset,
  });
}
