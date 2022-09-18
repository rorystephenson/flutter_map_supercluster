import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/supercluster_layer_base.dart';
import 'package:supercluster/supercluster.dart';

import 'cluster_data.dart';
import 'marker_event.dart';
import 'supercluster_controller.dart';
import 'supercluster_layer_options.dart';

class SuperclusterLayer extends SuperclusterLayerBase {
  /// Controller for replacing the markers. Note that this requires rebuilding
  /// the clusters and may take a second if you have many (~10000) markers.
  /// Consider using [SuperclusterMutableLayer] if you want to be able to
  /// add/remove [Marker]s quickly.
  @override
  final SuperclusterController? controller;

  const SuperclusterLayer({
    Key? key,
    required SuperclusterLayerOptions options,
    this.controller,
  }) : super(key: key, options: options);

  @override
  State<SuperclusterLayer> createState() => _SuperclusterLayerState();
}

class _SuperclusterLayerState
    extends SuperclusterLayerStateBase<SuperclusterLayer> {
  late Supercluster<Marker> _supercluster;

  @override
  void initializeClusterManager(List<Marker> markers) {
    _supercluster = Supercluster<Marker>(
      points: markers,
      getX: (m) => m.point.longitude,
      getY: (m) => m.point.latitude,
      minZoom: minZoom,
      maxZoom: maxZoom,
      extractClusterData: (marker) => ClusterData(
        marker,
        innerExtractor: widget.options.clusterDataExtractor,
      ),
      radius: widget.options.maxClusterRadius,
      minPoints: widget.options.minimumClusterSize,
    );
  }

  @override
  void onMarkerEvent(
    FlutterMapState mapState,
    MarkerEvent markerEvent,
  ) {
    if (markerEvent is ReplaceAllMarkerEvent) {
      initializeClusterManager(markerEvent.markers);
    } else {
      throw 'Unsupported $MarkerEvent type: ${markerEvent.runtimeType}. Try using SuperclusterMutableLayer.';
    }

    mapState.mapController.move(mapState.center, mapState.zoom);
  }

  @override
  List<Marker> getAllMarkers() {
    return _supercluster.getLeaves().toList();
  }

  @override
  List<LayerElement<Marker>> search(
    double westLng,
    double southLat,
    double eastLng,
    double northLat,
    int zoom,
  ) =>
      _supercluster.search(westLng, southLat, eastLng, northLat, zoom);
}
