import 'dart:async';

import 'package:flutter_map/plugin_api.dart';

import 'cluster_data.dart';

class FastClusterLayerController {
  final StreamController<MarkerEvent> _markerEventController;

  FastClusterLayerController()
      : _markerEventController = StreamController.broadcast();

  factory FastClusterLayerController.mutable({
    Function(ClusterData? aggregatedClusterData)? onClusterDataChange,
  }) = MutableFastClusterLayerController;

  Stream<MarkerEvent> get markerEventStream => _markerEventController.stream;

  /// Remove all of the existing Markers and replace them with [markers]. Note
  /// that this requires completely rebuilding the clusters and may be a slow
  /// operation. If you want to add/remove some markers you should use a
  /// mutable controller (via [FastClusterLayerController.mutable]) and use the
  /// add/remove functions.
  void replaceAll(List<Marker> markers) {
    _markerEventController.add(ReplaceAllMarkerEvent(markers));
  }

  /// Clear all of the existing Markers.
  void clear() {
    _markerEventController.add(ReplaceAllMarkerEvent([]));
  }

  dispose() {
    _markerEventController.close();
  }
}

class MutableFastClusterLayerController extends FastClusterLayerController {
  /// An optional function which will be called whenever the aggregated cluster
  /// data of all points changes. Note that this will only be calculated if the
  /// callback is provided.
  final void Function(ClusterData? aggregatedClusterData)? onClusterDataChange;

  MutableFastClusterLayerController({
    this.onClusterDataChange,
  });

  /// Add a single Marker. This Marker will be clustered if possible.
  void add(Marker marker) {
    _markerEventController.add(AddMarkerEvent(marker));
  }

  /// Remove a single Marker. This may cause some clusters to be split and
  /// rebuilt.
  void remove(Marker marker) {
    _markerEventController.add(RemoveMarkerEvent(marker));
  }

  /// Modify a Marker. Note that [oldMarker] must have the same [pos] as
  /// [newMarker]. This is an optimised function that skips re-clustering.
  void modifyMarker(Marker oldMarker, Marker newMarker,
      {bool updateParentClusters = true}) {
    assert(oldMarker.point == newMarker.point);
    _markerEventController.add(ModifyMarkerEvent(
      oldMarker,
      newMarker,
      updateParentClusters: updateParentClusters,
    ));
  }
}

abstract class MarkerEvent {}

class AddMarkerEvent extends MarkerEvent {
  final Marker marker;

  AddMarkerEvent(this.marker);
}

class RemoveMarkerEvent extends MarkerEvent {
  final Marker marker;

  RemoveMarkerEvent(this.marker);
}

class ReplaceAllMarkerEvent extends MarkerEvent {
  final List<Marker> markers;

  ReplaceAllMarkerEvent(this.markers);
}

class ModifyMarkerEvent extends MarkerEvent {
  final Marker oldMarker;
  final Marker newMarker;
  final bool updateParentClusters;

  ModifyMarkerEvent(
    this.oldMarker,
    this.newMarker, {
    required this.updateParentClusters,
  });
}
