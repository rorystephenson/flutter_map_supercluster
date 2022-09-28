import 'dart:async';

import 'package:flutter_map/plugin_api.dart';
import 'package:supercluster/supercluster.dart';

import 'marker_event.dart';
import 'supercluster_controller.dart';
import 'supercluster_state.dart';

class SuperclusterControllerImpl
    implements SuperclusterImmutableController, SuperclusterMutableController {
  final StreamController<MarkerEvent> _markerEventController;
  final StreamController<SuperclusterState> _stateStreamController;
  Future<Supercluster<Marker>> _supercluster = Future.any([]);

  SuperclusterControllerImpl()
      : _markerEventController = StreamController.broadcast(),
        _stateStreamController =
            StreamController<SuperclusterState>.broadcast();

  Stream<MarkerEvent> get stream => _markerEventController.stream;

  @override
  Stream<SuperclusterState> get stateStream =>
      _stateStreamController.stream.distinct();

  void setSupercluster(Future<Supercluster<Marker>> supercluster) {
    _supercluster = supercluster;
  }

  @override
  void add(Marker marker) {
    _markerEventController.add(AddMarkerEvent(marker));
  }

  @override
  void remove(Marker marker) {
    _markerEventController.add(RemoveMarkerEvent(marker));
  }

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

  void removeSupercluster() {
    _supercluster = Future.any([]);
  }

  @override
  void replaceAll(List<Marker> markers) {
    _markerEventController.add(ReplaceAllMarkerEvent(markers));
  }

  @override
  void clear() {
    _markerEventController.add(ReplaceAllMarkerEvent([]));
  }

  @override
  Future<Iterable<Marker>> all() {
    return _supercluster.then((supercluster) => supercluster.getLeaves());
  }

  void updateState(SuperclusterState newState) {
    _stateStreamController.add(newState);
  }

  @override
  void dispose() {
    _markerEventController.close();
    _stateStreamController.close();
  }
}
