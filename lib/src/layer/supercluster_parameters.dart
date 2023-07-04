import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/layer/supercluster_config.dart';
import 'package:supercluster/supercluster.dart';

class SuperclusterParameters implements SuperclusterConfig {
  final SuperclusterConfig config;
  final List<Marker> markers;

  SuperclusterParameters({
    required this.config,
    required this.markers,
  });

  @override
  ClusterDataBase Function(Marker marker)? get innerClusterDataExtractor =>
      config.innerClusterDataExtractor;

  @override
  bool get isMutableSupercluster => config.isMutableSupercluster;

  @override
  int get maxClusterRadius => config.maxClusterRadius;

  @override
  int get maxZoom => config.maxZoom;

  @override
  int get minZoom => config.minZoom;

  @override
  int? get minimumClusterSize => config.minimumClusterSize;
}
