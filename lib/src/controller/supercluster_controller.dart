import 'package:flutter_map/plugin_api.dart';

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

  /// Show popups for the given [markers]. If a popup is already showing for a
  /// given marker it remains visible.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when showing the popups.
  ///
  /// Do not use PopupController for controlling Supercluster marker popups,
  /// see [SuperclusterController] documentation above for more info.
  void showPopupsAlsoFor(List<Marker> markers, {bool disableAnimation = false});

  /// Show popups only for the given [markers]. All other popups will be
  /// hidden. If a popup is already showing for a given marker it remains
  /// visible.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when showing/hiding the popups.
  ///
  /// Do not use PopupController for controlling Supercluster marker popups,
  /// see [SuperclusterController] documentation above for more info.
  void showPopupsOnlyFor(List<Marker> markers, {bool disableAnimation = false});

  /// Hide all popups that are showing.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when hiding the popups.
  ///
  /// Do not use PopupController for controlling Supercluster marker popups,
  /// see [SuperclusterController] documentation above for more info.
  void hideAllPopups({bool disableAnimation = false});

  /// Hide popups for which the provided [test] return true.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when hiding the popups.
  ///
  /// Do not use PopupController for controlling Supercluster marker popups,
  /// see [SuperclusterController] documentation above for more info.
  void hidePopupsWhere(
    bool Function(Marker marker) test, {
    bool disableAnimation = false,
  });

  /// Hide popups showing for any of the given markers.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when hiding the popups.
  ///
  /// Do not use PopupController for controlling Supercluster marker popups,
  /// see [SuperclusterController] documentation above for more info.
  void hidePopupsOnlyFor(List<Marker> markers, {bool disableAnimation = false});

  /// Hide the popup if it is showing for the given [marker], otherwise show it
  /// for that [marker].
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when showing/hiding the popup.
  ///
  /// Do not use PopupController for controlling Supercluster marker popups,
  /// see [SuperclusterController] documentation above for more info.
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
