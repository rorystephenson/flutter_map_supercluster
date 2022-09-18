import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/supercluster_layer_base.dart';
import 'package:supercluster/supercluster.dart';

import 'cluster_data.dart';
import 'marker_event.dart';
import 'supercluster_controller.dart';
import 'supercluster_layer_options.dart';

class SuperclusterMutableLayer extends SuperclusterLayerBase {
  /// Controller for adding/removing/replacing [Marker]s.
  @override
  final SuperclusterMutableController? controller;

  /// An optional function which will be called whenever the aggregated cluster
  /// data of all points changes. Note that this will only be calculated if the
  /// callback is provided.
  final void Function(ClusterData? aggregatedClusterData)? onClusterDataChange;

  const SuperclusterMutableLayer({
    Key? key,
    required SuperclusterLayerOptions options,
    this.controller,
    this.onClusterDataChange,
  }) : super(key: key, options: options);

  @override
  State<SuperclusterMutableLayer> createState() =>
      _SuperclusterMutableLayerState();
}

class _SuperclusterMutableLayerState
    extends SuperclusterLayerStateBase<SuperclusterMutableLayer> {
  late SuperclusterMutable<Marker> _supercluster;

  @override
  void initializeClusterManager(List<Marker> markers) {
    _supercluster = SuperclusterMutable<Marker>(
      getX: (m) => m.point.longitude,
      getY: (m) => m.point.latitude,
      minZoom: minZoom,
      maxZoom: maxZoom,
      minPoints: widget.options.minimumClusterSize,
      extractClusterData: (marker) => ClusterData(
        marker,
        innerExtractor: widget.options.clusterDataExtractor,
      ),
      radius: widget.options.maxClusterRadius,
      onClusterDataChange: widget.onClusterDataChange == null
          ? null
          : (clusterData) =>
              widget.onClusterDataChange!(clusterData as ClusterData?),
    )..load(markers);
  }

  @override
  void onMarkerEvent(
    FlutterMapState mapState,
    MarkerEvent markerEvent,
  ) {
    if (markerEvent is AddMarkerEvent) {
      _supercluster.insert(markerEvent.marker);
    } else if (markerEvent is RemoveMarkerEvent) {
      _supercluster.remove(markerEvent.marker);
    } else if (markerEvent is ReplaceAllMarkerEvent) {
      initializeClusterManager(markerEvent.markers);
    } else if (markerEvent is ModifyMarkerEvent) {
      _supercluster.modifyPointData(
        markerEvent.oldMarker,
        markerEvent.newMarker,
        updateParentClusters: markerEvent.updateParentClusters,
      );
    } else {
      throw 'Unknown $MarkerEvent type ${markerEvent.runtimeType}';
    }

    mapState.mapController.move(mapState.center, mapState.zoom);
  }

  @override
  List<Marker> getAllMarkers() => _supercluster.getLeaves().toList();

  @override
  List<LayerElement<Marker>> search(double westLng, double southLat,
          double eastLng, double northLat, int zoom) =>
      _supercluster.search(westLng, southLat, eastLng, northLat, zoom);
}
