import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/layer/supercluster_layer.dart';
import 'package:flutter_map_supercluster/src/splay/displaced_marker.dart';
import 'package:flutter_map_supercluster/src/splay/displaced_marker_offset.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

/// Base class for delegates which control splaying of markers when a cluster's
/// Markers are too close to uncluster at the max zoom.
abstract class ClusterSplayDelegate {
  final Duration duration;
  final double distance;
  final Curve curve;

  const ClusterSplayDelegate({
    /// Duration of the splay animation.
    required this.duration,

    /// How far the markers are splayed from the cluster.
    this.distance = 70.0,

    /// The Curve of the splay animation.
    this.curve = Curves.easeInOut,
  });

  /// Caluclate the maximum displacement of the [markers].
  List<DisplacedMarker> displaceMarkers(
    List<Marker> markers, {
    required LatLng clusterPosition,
    required CustomPoint Function(LatLng latLng) project,
    required LatLng Function(CustomPoint point) unproject,
  });

  /// Calculate the marker offsets at the given [animationProgress].
  List<DisplacedMarkerOffset> displacedMarkerOffsets(
    List<DisplacedMarker> displacedMarkers,
    double animationProgress,
    CustomPoint<num> Function(LatLng point) getPixelOffset,
    CustomPoint clusterPosition,
  );

  /// Create an optional decoration such as lines from the markers to the
  /// center which will be drawn below the cluster marker and the markers.
  /// This decoration will be within a Positioned whose size is twice this
  // delegate's [distance] and which is centered over the cluster.
  Widget? splayDecoration(List<DisplacedMarkerOffset> displacedMarkerOffsets);

  /// Optionally override this method to customise the cluster when it is splayed.
  Widget buildCluster(
    BuildContext context,
    ClusterWidgetBuilder clusterBuilder,
    LatLng position,
    int markerCount,
    ClusterDataBase? extraClusterData,
    double animationProgress,
  ) =>
      clusterBuilder(
        context,
        position,
        markerCount,
        extraClusterData,
      );
}
