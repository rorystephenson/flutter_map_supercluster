import 'dart:ui';

import 'package:flutter_map/plugin_api.dart';
import 'package:supercluster/supercluster.dart';

class ClusterData extends ClusterDataBase {
  final int markerCount;
  late final Size? visualSize;
  final Size Function(
          ClusterData clusterData, ClusterDataBase? extraClusterData)
      _computeVisualSize;

  final ClusterDataBase Function(Marker)? _innerExtractor;
  final ClusterDataBase? innerData;

  ClusterData(
    Marker marker, {
    required Size Function(
            ClusterData clusterData, ClusterDataBase? extraClusterData)
        computeVisualSize,
    ClusterDataBase Function(Marker)? innerExtractor,
  })  : markerCount = 1,
        _computeVisualSize = computeVisualSize,
        visualSize = null,
        _innerExtractor = innerExtractor,
        innerData = innerExtractor?.call(marker);

  ClusterData._combined(this.markerCount,
      {required Size Function(
              ClusterData clusterData, ClusterDataBase? extraClusterData)
          computeVisualSize,
      ClusterDataBase Function(Marker)? innerExtractor,
      this.innerData})
      : _computeVisualSize = computeVisualSize,
        _innerExtractor = innerExtractor {
    visualSize = _computeVisualSize(this, innerData);
  }

  @override
  ClusterData combine(covariant ClusterData point) {
    return ClusterData._combined(
      markerCount + point.markerCount,
      computeVisualSize: _computeVisualSize,
      innerExtractor: _innerExtractor,
      innerData: innerData?.combine(point.innerData!),
    );
  }
}
