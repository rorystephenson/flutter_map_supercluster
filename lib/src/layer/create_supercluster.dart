import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/layer/cluster_data.dart';
import 'package:flutter_map_supercluster/src/layer/supercluster_parameters.dart';
import 'package:supercluster/supercluster.dart';

Supercluster<Marker> createSupercluster(SuperclusterParameters parameters) {
  return parameters.isMutableSupercluster
      ? _loadMutable(parameters)
      : _loadImmutable(parameters);
}

SuperclusterMutable<Marker> _loadMutable(SuperclusterParameters parameters) {
  return SuperclusterMutable<Marker>(
    getX: (m) => m.point.longitude,
    getY: (m) => m.point.latitude,
    minZoom: parameters.minZoom,
    maxZoom: parameters.maxZoom,
    minPoints: parameters.minimumClusterSize,
    extractClusterData: (marker) => ClusterData(
      marker,
      innerExtractor: parameters.innerClusterDataExtractor,
    ),
    radius: parameters.maxClusterRadius,
  )..load(parameters.markers);
}

SuperclusterImmutable<Marker> _loadImmutable(
    SuperclusterParameters parameters) {
  return SuperclusterImmutable<Marker>(
    getX: (m) => m.point.longitude,
    getY: (m) => m.point.latitude,
    minZoom: parameters.minZoom,
    maxZoom: parameters.maxZoom,
    extractClusterData: (marker) => ClusterData(
      marker,
      innerExtractor: parameters.innerClusterDataExtractor,
    ),
    radius: parameters.maxClusterRadius,
    minPoints: parameters.minimumClusterSize,
  )..load(parameters.markers);
}
