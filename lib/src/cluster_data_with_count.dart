import 'package:flutter_map/plugin_api.dart';
import 'package:supercluster/supercluster.dart';

class ClusterDataWithCount extends ClusterDataBase {
  final int markerCount;

  final ClusterDataBase Function(Marker)? _customDataExtractor;
  final ClusterDataBase? customData;

  ClusterDataWithCount(
    Marker marker, {
    ClusterDataBase Function(Marker)? customDataExtractor,
  })  : markerCount = 1,
        _customDataExtractor = customDataExtractor,
        customData = customDataExtractor?.call(marker);

  ClusterDataWithCount._combined(
    this.markerCount, {
    ClusterDataBase Function(Marker)? innerExtractor,
    this.customData,
  }) : _customDataExtractor = innerExtractor;

  @override
  ClusterDataWithCount combine(covariant ClusterDataWithCount point) {
    return ClusterDataWithCount._combined(
      markerCount + point.markerCount,
      innerExtractor: _customDataExtractor,
      customData: customData?.combine(point.customData!),
    );
  }
}
