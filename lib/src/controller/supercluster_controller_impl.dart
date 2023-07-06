import 'dart:async';

import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/controller/marker_matcher.dart';
import 'package:flutter_map_supercluster/src/controller/supercluster_event.dart';
import 'package:latlong2/latlong.dart';

import 'supercluster_controller.dart';

class SuperclusterControllerImpl
    implements SuperclusterImmutableController, SuperclusterMutableController {
  final StreamController<SuperclusterEvent> _superclusterEventController;

  SuperclusterControllerImpl()
      : _superclusterEventController = StreamController.broadcast();

  Stream<SuperclusterEvent> get stream => _superclusterEventController.stream;

  @override
  void add(Marker marker) {
    _superclusterEventController.add(AddMarkerEvent(marker));
  }

  @override
  void addAll(List<Marker> markers) {
    _superclusterEventController.add(AddAllMarkerEvent(markers));
  }

  @override
  void remove(Marker marker) {
    _superclusterEventController.add(RemoveMarkerEvent(marker));
  }

  @override
  void removeAll(List<Marker> markers) {
    _superclusterEventController.add(RemoveAllMarkerEvent(markers));
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

  @override
  void replaceAll(List<Marker> markers) {
    _superclusterEventController.add(ReplaceAllMarkerEvent(markers));
  }

  @override
  void clear() {
    _superclusterEventController.add(const ReplaceAllMarkerEvent([]));
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
  }
}
