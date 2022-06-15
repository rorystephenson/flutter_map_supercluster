import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_fast_cluster/flutter_map_fast_cluster.dart';

class SuperclusterClusterManager extends ClusterManager {
  static const defaultMinZoom = 1;
  static const defaultMaxZoom = 20;

  late final Supercluster<Marker> _supercluster;
  final Size maximumMarkerOrClusterSize;

  SuperclusterClusterManager({
    required List<Marker> markers,
    required this.maximumMarkerOrClusterSize,

    /// The maximum radius in pixels that a cluster can cover.
    int maxClusterRadius = 80,

    /// The minimum number of points required to form a cluster, if there is less
    /// than this number of points within the [maxClusterRadius] the markers will
    /// be left unclustered.
    int? minimumClusterSize,

    /// Implement this function to extract extra data from Markers which can be
    /// used in the [builder] and [computeSize].
    ClusterDataBase Function(Marker marker)? clusterDataExtractor,
    int minZoom = defaultMinZoom,
    int maxZoom = defaultMaxZoom,
  }) {
    _supercluster = Supercluster<Marker>(
      points: markers,
      getX: (m) => m.point.longitude,
      getY: (m) => m.point.latitude,
      minZoom: minZoom,
      maxZoom: maxZoom,
      extractClusterData:
          clusterDataExtractor ?? (marker) => ClusterDataWithCount(marker),
      radius: maxClusterRadius,
      minPoints: minimumClusterSize,
    );
  }

  void getClusters() {}

  @override
  List<ClusterOrMapPoint<Marker>> getClustersAndPointsIn(
      LatLngBounds bounds, int zoom) {
    return _supercluster.getClustersAndPoints(
      bounds.west,
      bounds.south,
      bounds.east,
      bounds.north,
      zoom,
    );
  }

  @override
  double getClusterExpansionZoom(Cluster<Marker> cluster) {
    return _supercluster.getClusterExpansionZoom(cluster.id).toDouble();
  }

  @override
  Widget? buildRotatedOverlay(
          BuildContext context, MapCalculator mapCalculator) =>
      null;

  @override
  Widget? buildNonRotatedOverlay(
          BuildContext context, MapCalculator mapCalculator) =>
      null;
}
