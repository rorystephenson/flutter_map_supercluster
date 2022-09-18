import 'dart:async';

import 'package:flutter_map/plugin_api.dart';

import 'marker_event.dart';
import 'supercluster_controller.dart';

abstract class SuperclusterControllerBase {
  final StreamController<MarkerEvent> _markerEventController;

  SuperclusterControllerBase()
      : _markerEventController = StreamController.broadcast();

  Stream<MarkerEvent> get stream => _markerEventController.stream;

  dispose() {
    _markerEventController.close();
  }
}

class SuperclusterControllerImpl extends SuperclusterControllerBase
    implements SuperclusterController {
  /// Remove all of the existing Markers and replace them with [markers]. Note
  /// that this requires completely rebuilding the clusters and may be a slow
  /// operation. If you want to add/remove some markers you should use
  /// [SuperclusterMutableLayer] with [SuperclusterMutableControllerImpl] and use
  /// the add/remove functions.
  @override
  void replaceAll(List<Marker> markers) {
    _markerEventController.add(ReplaceAllMarkerEvent(markers));
  }

  /// Clear all of the existing Markers.
  @override
  void clear() {
    _markerEventController.add(ReplaceAllMarkerEvent([]));
  }

  @override
  dispose() {
    _markerEventController.close();
  }
}

class SuperclusterMutableControllerImpl extends SuperclusterControllerBase
    implements SuperclusterMutableController {
  /// Add a single [Marker]. This [Marker] will be clustered if possible.
  @override
  void add(Marker marker) {
    _markerEventController.add(AddMarkerEvent(marker));
  }

  /// Remove a single [Marker]. This may cause some clusters to be split and
  /// rebuilt.
  @override
  void remove(Marker marker) {
    _markerEventController.add(RemoveMarkerEvent(marker));
  }

  /// Modify a Marker. Note that [oldMarker] must have the same [pos] as
  /// [newMarker]. This is an optimised function that skips re-clustering.
  @override
  void modifyMarker(Marker oldMarker, Marker newMarker,
      {bool updateParentClusters = true}) {
    assert(oldMarker.point == newMarker.point);
    _markerEventController.add(ModifyMarkerEvent(
      oldMarker,
      newMarker,
      updateParentClusters: updateParentClusters,
    ));
  }

  /// Remove all of the existing Markers and replace them with [markers]. Note
  /// that this requires completely rebuilding the clusters and may be a slow
  /// operation. If you want to add/remove some markers you should use the
  /// [add]/[remove] functions.
  @override
  void replaceAll(List<Marker> markers) {
    _markerEventController.add(ReplaceAllMarkerEvent(markers));
  }

  /// Clear all of the existing Markers.
  @override
  void clear() {
    _markerEventController.add(ReplaceAllMarkerEvent([]));
  }
}
