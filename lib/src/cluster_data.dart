import 'package:flutter_map/plugin_api.dart';
import 'package:supercluster/supercluster.dart';

class ClusterData extends ClusterDataBase {
  final int markerCount;

  final ClusterDataBase Function(Marker)? _innerExtractor;
  final ClusterDataBase? innerData;

  ClusterData(
    Marker marker, {
    ClusterDataBase Function(Marker)? innerExtractor,
  })  : markerCount = 1,
        _innerExtractor = innerExtractor,
        innerData = innerExtractor?.call(marker);

  ClusterData._combined(
    this.markerCount, {
    ClusterDataBase Function(Marker)? innerExtractor,
    this.innerData,
  }) : _innerExtractor = innerExtractor;

  @override
  ClusterData combine(covariant ClusterData data) {
    return ClusterData._combined(
      markerCount + data.markerCount,
      innerExtractor: _innerExtractor,
      innerData: innerData?.combine(data.innerData!),
    );
  }
}
