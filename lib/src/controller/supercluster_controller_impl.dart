import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_supercluster/src/controller/marker_matcher.dart';
import 'package:flutter_map_supercluster/src/controller/supercluster_event.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

import 'supercluster_controller.dart';
import 'supercluster_state.dart';

class SuperclusterControllerImpl
    implements SuperclusterImmutableController, SuperclusterMutableController {
  final bool createdInternally;
  final StreamController<SuperclusterEvent> _superclusterEventController;
  final StreamController<SuperclusterState> _stateStreamController;
  Future<Supercluster<Marker>> _supercluster = Future.any([]);

  SuperclusterControllerImpl({required this.createdInternally})
      : _superclusterEventController = StreamController.broadcast(),
        _stateStreamController =
            StreamController<SuperclusterState>.broadcast();

  Stream<SuperclusterEvent> get stream => _superclusterEventController.stream;

  @override
  Stream<SuperclusterState> get stateStream =>
      _stateStreamController.stream.distinct();

  void setSupercluster(Future<Supercluster<Marker>> supercluster) {
    _supercluster = supercluster;
  }

  @override
  void add(Marker marker) {
    _superclusterEventController.add(AddMarkerEvent(marker));
  }

  @override
  void remove(Marker marker) {
    _superclusterEventController.add(RemoveMarkerEvent(marker));
  }

  @override
  void modifyMarker(
    Marker oldMarker,
    Marker newMarker, {
    bool updateParentClusters = true,
  }) {
    assert(oldMarker.point == newMarker.point);
    _superclusterEventController.add(ModifyMarkerEvent(
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
    _superclusterEventController.add(ReplaceAllMarkerEvent(markers));
  }

  @override
  void clear() {
    _superclusterEventController.add(const ReplaceAllMarkerEvent([]));
  }

  @override
  Future<Iterable<Marker>> all() {
    return _supercluster.then((supercluster) => supercluster.getLeaves());
  }

  @override
  void collapseSplayedClusters() {
    _superclusterEventController.add(const CollapseSplayedClustersEvent());
  }

  @override
  void moveToMarker(
    MarkerMatcher markerMatcher, {
    bool showPopup = true,
    FutureOr<void> Function(LatLng center, double zoom)? moveMap,
  }) {
    _superclusterEventController.add(
      MoveToMarkerEvent(
        markerMatcher: markerMatcher,
        showPopup: showPopup,
        moveMap: moveMap,
      ),
    );
  }

  void updateState(SuperclusterState newState) {
    _stateStreamController.add(newState);
  }

  @override
  void showPopupsAlsoFor(
    List<Marker> markers, {
    bool disableAnimation = false,
  }) {
    _superclusterEventController.add(
      ShowPopupsAlsoForEvent(markers, disableAnimation: false),
    );
  }

  @override
  void showPopupsOnlyFor(
    List<Marker> markers, {
    bool disableAnimation = false,
  }) {
    _superclusterEventController.add(
      ShowPopupsOnlyForEvent(markers, disableAnimation: false),
    );
  }

  @override
  void hideAllPopups({bool disableAnimation = false}) {
    _superclusterEventController.add(
      const HideAllPopupsEvent(disableAnimation: false),
    );
  }

  @override
  void hidePopupsWhere(
    bool Function(Marker marker) test, {
    bool disableAnimation = false,
  }) {
    _superclusterEventController.add(
      HidePopupsWhereEvent(test, disableAnimation: disableAnimation),
    );
  }

  @override
  void hidePopupsOnlyFor(
    List<Marker> markers, {
    bool disableAnimation = false,
  }) {
    _superclusterEventController.add(
      HidePopupsOnlyForEvent(markers, disableAnimation: disableAnimation),
    );
  }

  @override
  void togglePopup(Marker marker, {bool disableAnimation = false}) {
    _superclusterEventController.add(
      TogglePopupEvent(marker, disableAnimation: disableAnimation),
    );
  }

  @override
  void dispose() {
    _superclusterEventController.close();
    _stateStreamController.close();
  }
}
