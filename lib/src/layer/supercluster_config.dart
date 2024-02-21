import 'package:flutter_map/flutter_map.dart';
import 'package:supercluster/supercluster.dart';

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
