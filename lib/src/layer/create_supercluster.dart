import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_supercluster/src/layer/cluster_data.dart';
import 'package:flutter_map_supercluster/src/layer/supercluster_config.dart';
import 'package:supercluster/supercluster.dart';

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
