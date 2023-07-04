import 'package:equatable/equatable.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:supercluster/supercluster.dart';

/// This describes the options needed to create a Supercluster but does not
/// contain the Markers. See SuperclusterParameters for the options and the
/// Markers in a single class.
///
/// This is defined as abstract to allow SuperclusterParameters to implement it
/// without needing to implement Equatable methods since Equatable is used on
/// SuperclusterConfigImpl.
abstract class SuperclusterConfig {
  static const defaultMinZoom = 1;
  static const defaultMaxZoom = 20;

  bool get isMutableSupercluster;
  int get maxClusterRadius;
  ClusterDataBase Function(Marker marker)? get innerClusterDataExtractor;
  int? get minimumClusterSize;

  int get minZoom;
  int get maxZoom;

  const SuperclusterConfig();
}

class SuperclusterConfigImpl extends Equatable implements SuperclusterConfig {
  @override
  final bool isMutableSupercluster;
  @override
  final int maxClusterRadius;
  @override
  final ClusterDataBase Function(Marker marker)? innerClusterDataExtractor;
  @override
  final int? minimumClusterSize;

  final int? _maxClusterZoom;
  final int? _mapStateMinZoom;
  final int? _mapStateMaxZoom;

  SuperclusterConfigImpl({
    required FlutterMapState mapState,
    required this.isMutableSupercluster,
    required int? maxClusterZoom,
    required this.maxClusterRadius,
    required this.innerClusterDataExtractor,
    required this.minimumClusterSize,
  })  : _maxClusterZoom = maxClusterZoom,
        _mapStateMinZoom = _mapStateMinZoomFrom(mapState),
        _mapStateMaxZoom = _mapStateMaxZoomFrom(mapState);

  @override
  int get minZoom => _mapStateMinZoom ?? SuperclusterConfig.defaultMinZoom;
  @override
  int get maxZoom =>
      _maxClusterZoom ?? _mapStateMaxZoom ?? SuperclusterConfig.defaultMaxZoom;

  bool mapStateZoomLimitsHaveChanged(FlutterMapState mapState) =>
      _mapStateMaxZoom != _mapStateMaxZoomFrom(mapState) ||
      _mapStateMinZoom != _mapStateMinZoomFrom(mapState);

  static int? _mapStateMinZoomFrom(FlutterMapState mapState) =>
      mapState.options.minZoom?.ceil();

  static int? _mapStateMaxZoomFrom(FlutterMapState mapState) =>
      mapState.options.maxZoom?.ceil();

  @override
  List<Object?> get props => [
        isMutableSupercluster,
        minZoom,
        maxZoom,
        maxClusterRadius,
        innerClusterDataExtractor,
        minimumClusterSize,
      ];
}
