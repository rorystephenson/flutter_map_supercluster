import 'package:flutter_map/plugin_api.dart';
import 'package:supercluster/supercluster.dart';

import 'cluster_data.dart';

class SuperclusterConfig {
  final bool isMutableSupercluster;

  final List<Marker> markers;

  final int minZoom;
  final int maxZoom;

  final ClusterDataBase Function(Marker marker)? innerClusterDataExtractor;
  final int maxClusterRadius;
  final int? minimumClusterSize;

  SuperclusterConfig({
    required this.isMutableSupercluster,
    required this.markers,
    required this.minZoom,
    required this.maxZoom,
    required this.maxClusterRadius,
    required this.innerClusterDataExtractor,
    this.minimumClusterSize,
  });
}

Supercluster<Marker> createSupercluster(SuperclusterConfig config) {
  return config.isMutableSupercluster
      ? _loadMutable(config)
      : _loadImmutable(config);
}

SuperclusterMutable<Marker> _loadMutable(SuperclusterConfig config) {
  return SuperclusterMutable<Marker>(
    getX: (m) => m.point.longitude,
    getY: (m) => m.point.latitude,
    minZoom: config.minZoom,
    maxZoom: config.maxZoom,
    minPoints: config.minimumClusterSize,
    extractClusterData: (marker) => ClusterData(
      marker,
      innerExtractor: config.innerClusterDataExtractor,
    ),
    radius: config.maxClusterRadius,
  )..load(config.markers);
}

SuperclusterImmutable<Marker> _loadImmutable(SuperclusterConfig config) {
  return SuperclusterImmutable<Marker>(
    getX: (m) => m.point.longitude,
    getY: (m) => m.point.latitude,
    minZoom: config.minZoom,
    maxZoom: config.maxZoom,
    extractClusterData: (marker) => ClusterData(
      marker,
      innerExtractor: config.innerClusterDataExtractor,
    ),
    radius: config.maxClusterRadius,
    minPoints: config.minimumClusterSize,
  )..load(config.markers);
}
