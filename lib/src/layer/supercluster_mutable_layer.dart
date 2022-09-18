import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/layer/supercluster_layer_base.dart';
import 'package:supercluster/supercluster.dart';

import '../controller/marker_event.dart';
import '../controller/supercluster_controller.dart';
import '../options/animation_options.dart';
import 'cluster_data.dart';

class SuperclusterMutableLayer extends SuperclusterLayerBase {
  /// Controller for adding/removing/replacing [Marker]s.
  @override
  final SuperclusterMutableController? controller;

  /// An optional function which will be called whenever the aggregated cluster
  /// data of all points changes. Note that this will only be calculated if the
  /// callback is provided.
  final void Function(ClusterData? aggregatedClusterData)? onClusterDataChange;

  const SuperclusterMutableLayer({
    super.key,
    required super.builder,
    this.controller,
    this.onClusterDataChange,
    super.initialMarkers = const [],
    super.onMarkerTap,
    super.minimumClusterSize,
    super.maxClusterRadius = 80,
    super.clusterDataExtractor,
    super.clusterWidgetSize = const Size(30, 30),
    super.clusterZoomAnimation = const AnimationOptions.animate(
      curve: Curves.linear,
      velocity: 1,
    ),
    super.popupOptions,
    super.rotate,
    super.rotateOrigin,
    super.rotateAlignment,
    super.anchor,
  });

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
      minPoints: widget.minimumClusterSize,
      extractClusterData: (marker) => ClusterData(
        marker,
        innerExtractor: widget.clusterDataExtractor,
      ),
      radius: widget.maxClusterRadius,
      onClusterDataChange: widget.onClusterDataChange == null
          ? null
          : (clusterData) =>
              widget.onClusterDataChange!(clusterData as ClusterData?),
    )..load(markers);
  }

  @override
  void onMarkerEvent(MarkerEvent markerEvent) {
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

    setState(() {});
  }

  @override
  List<Marker> getAllMarkers() => _supercluster.getLeaves().toList();

  @override
  List<LayerElement<Marker>> search(double westLng, double southLat,
          double eastLng, double northLat, int zoom) =>
      _supercluster.search(westLng, southLat, eastLng, northLat, zoom);
}
