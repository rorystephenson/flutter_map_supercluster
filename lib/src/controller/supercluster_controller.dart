import 'package:flutter_map/plugin_api.dart';

import 'supercluster_controller_impl.dart';
import 'supercluster_state.dart';

abstract class SuperclusterController {
  void dispose();
}

abstract class SuperclusterImmutableController extends SuperclusterController {
  factory SuperclusterImmutableController() => SuperclusterControllerImpl();

  /// A Stream of the [SuperclusterState]. Note that the [SuperclusterState]'s
  /// aggregatedClusterData will not be calculated unless [SuperclusterLayer]'s
  /// [calculateAggregatedClusterData] is true.
  Stream<SuperclusterState> get stateStream;

  /// Remove all of the existing Markers and replace them with [markers]. Note
  /// that this requires completely rebuilding the clusters and may be a slow
  /// operation. If you want to add/remove some markers you should use
  /// [SuperclusterMutableLayer] with [SuperclusterMutableControllerImpl] and use
  /// the add/remove functions.
  void replaceAll(List<Marker> markers);

  /// Clear all of the existing Markers.
  void clear();

  /// A Future that completes with an Iterable of all Markers in the order that
  /// the inner cluster store holds them. The Future will complete when the
  /// controller is associated with a layer and the loading of the supercluster
  /// finishes.
  Future<Iterable<Marker>> all();
}

abstract class SuperclusterMutableController extends SuperclusterController {
  factory SuperclusterMutableController() => SuperclusterControllerImpl();

  /// A Stream of the [SuperclusterState]. Note that the [SuperclusterState]'s
  /// aggregatedClusterData will not be calculated unless [SuperclusterLayer]'s
  /// [calculateAggregatedClusterData] is true. A new state is emitted only if
  /// it is different from the previous state.
  Stream<SuperclusterState> get stateStream;

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

  /// An Iterable of all Markers in the order that the inner cluster store holds
  /// them. Note that this will throw an exception if the controller is not yet
  /// associated with the layer, check [isAssociated] first.
  Future<Iterable<Marker>> all();
}
