import 'package:flutter_map/plugin_api.dart';

import 'supercluster_controller_impl.dart';

abstract class SuperclusterController extends SuperclusterControllerBase {
  factory SuperclusterController() => SuperclusterControllerImpl();

  /// Remove all of the existing Markers and replace them with [markers]. Note
  /// that this requires completely rebuilding the clusters and may be a slow
  /// operation. If you want to add/remove some markers you should use
  /// [SuperclusterMutableLayer] with [SuperclusterMutableControllerImpl] and use
  /// the add/remove functions.
  void replaceAll(List<Marker> markers);

  /// Clear all of the existing Markers.
  void clear();
}

abstract class SuperclusterMutableController
    extends SuperclusterControllerBase {
  factory SuperclusterMutableController() =>
      SuperclusterMutableControllerImpl();

  /// Add a single [Marker]. This [Marker] will be clustered if possible.
  void add(Marker marker);

  /// Remove a single [Marker]. This may cause some clusters to be split and
  /// rebuilt.
  void remove(Marker marker);

  /// Modify a Marker. Note that [oldMarker] must have the same [pos] as
  /// [newMarker]. This is an optimised function that skips re-clustering.
  void modifyMarker(Marker oldMarker, Marker newMarker,
      {bool updateParentClusters = true});

  /// Remove all of the existing Markers and replace them with [markers]. Note
  /// that this requires completely rebuilding the clusters and may be a slow
  /// operation. If you want to add/remove some markers you should use the
  /// [add]/[remove] functions.
  void replaceAll(List<Marker> markers);

  /// Clear all of the existing Markers.
  void clear();
}
