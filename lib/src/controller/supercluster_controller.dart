import 'dart:async';

import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/controller/marker_matcher.dart';
import 'package:latlong2/latlong.dart';

import 'supercluster_controller_impl.dart';
import 'supercluster_state.dart';

abstract class SuperclusterController {
  /// Clear all of the existing Markers.
  void clear();

  /// A Future that completes with an Iterable of all Markers in the order that
  /// the inner cluster store holds them. The Future will complete when the
  /// controller is associated with a layer and the loading of the supercluster
  /// finishes.
  Future<Iterable<Marker>> all();

  /// A Stream of the [SuperclusterState]. Note that the [SuperclusterState]'s
  /// aggregatedClusterData will not be calculated unless [SuperclusterLayer]'s
  /// [calculateAggregatedClusterData] is true.
  Stream<SuperclusterState> get stateStream;

  /// Collapses any splayed clusters. See SuperclusterLayer's
  /// [clusterSplayDelegate] for more information on splaying.
  void collapseSplayedClusters();

  /// Moves the map to make a [Marker] visible.
  void moveToMarker(
    MarkerMatcher markerMatcher, {
    /// Whether the target Marker's popup should be shown if the Marker is
    /// successfully found, defaults to true. This option has no affect if
    /// popups are disabled.
    bool showPopup = true,

    /// The [moveMap] callback may be provided to control the map movement that
    /// will occur to make the [Marker] visible. The [center] is the marker's
    /// position whilst the [zoom] is the current zoom if the marker is visible,
    /// otherwise it is the minimum zoom necessary to uncluster the marker. If
    /// the marker is in a splay cluster the cluster will be splayed once the
    /// move is complete. If no callback is provided the SuperclusterLayer's
    /// [moveMap] is used.
    FutureOr<void> Function(LatLng center, double zoom)? moveMap,
  });

  /// Show popups for the given [markers]. If a popup is already showing for a
  /// given marker it remains visible. If a marker is not visible at the
  /// current zoom the popup for that marker will not be shown.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when showing the popups.
  ///
  /// Has no effect if the SuperclusterLayer's popupOptions are null.
  void showPopupsAlsoFor(List<Marker> markers, {bool disableAnimation = false});

  /// Show popups only for the given [markers]. All other popups will be
  /// hidden. If a popup is already showing for a given marker it remains
  /// visible. If a marker is not visible at the current zoom the popup for
  /// that marker will not be shown.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when showing/hiding the popups.
  ///
  /// Has no effect if the SuperclusterLayer's popupOptions are null.
  void showPopupsOnlyFor(List<Marker> markers, {bool disableAnimation = false});

  /// Hide all popups that are showing.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when hiding the popups.
  ///
  /// Has no effect if the SuperclusterLayer's popupOptions are null.
  void hideAllPopups({bool disableAnimation = false});

  /// Hide popups for which the provided [test] return true.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when hiding the popups.
  ///
  /// Has no effect if the SuperclusterLayer's popupOptions are null.
  void hidePopupsWhere(
    bool Function(Marker marker) test, {
    bool disableAnimation = false,
  });

  /// Hide popups showing for any of the given markers.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when hiding the popups.
  ///
  /// Has no effect if the SuperclusterLayer's popupOptions are null.
  void hidePopupsOnlyFor(List<Marker> markers, {bool disableAnimation = false});

  /// Hide the popup if it is showing for the given [marker], otherwise show it
  /// for that [marker]. If the marker is not visible at the current zoom
  /// nothing happens.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when showing/hiding the popup.
  ///
  /// Has no effect if the SuperclusterLayer's popupOptions are null.
  void togglePopup(Marker marker, {bool disableAnimation = false});

  /// Dispose of this controller. Should be called when it is no longer used.
  void dispose();
}

abstract class SuperclusterImmutableController extends SuperclusterController {
  factory SuperclusterImmutableController() => SuperclusterControllerImpl();

  /// Remove all of the existing Markers and replace them with [markers]. Note
  /// that this requires completely rebuilding the clusters and may be a slow
  /// operation. If you want to add/remove some markers you should use
  /// [SuperclusterMutableLayer] with [SuperclusterMutableControllerImpl] and use
  /// the add/remove functions.
  void replaceAll(List<Marker> markers);
}

abstract class SuperclusterMutableController extends SuperclusterController {
  factory SuperclusterMutableController() => SuperclusterControllerImpl();

  /// Add a single [Marker]. This [Marker] will be clustered if possible.
  void add(Marker marker);

  /// Remove a single [Marker]. This may cause some clusters to be split and
  /// rebuilt.
  void remove(Marker marker);

  /// Modify a Marker. Note that [oldMarker] must have the same [pos] as
  /// [newMarker]. This is an optimised function that skips re-clustering.
  void modifyMarker(
    Marker oldMarker,
    Marker newMarker, {
    bool updateParentClusters = true,
  });

  /// Remove all of the existing Markers and replace them with [markers]. Note
  /// that this requires completely rebuilding the clusters and may be a slow
  /// operation. If you want to add/remove some markers you should use the
  /// [add]/[remove] functions.
  void replaceAll(List<Marker> markers);
}
