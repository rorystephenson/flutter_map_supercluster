import 'package:flutter_map/plugin_api.dart';

import '../layer/cluster_data.dart';
import 'supercluster_controller_impl.dart';

abstract class SuperclusterImmutableController
    extends SuperclusterControllerBase {
  factory SuperclusterImmutableController() =>
      SuperclusterImmutableControllerImpl();

  /// Indicates whether this controller is associated with the
  /// SuperclusterImmutableLayer.
  bool get isAssociated;

  /// An Stream of the aggregated cluster data of all points. Note that this
  /// will only be calculated if the stream is being listened to.
  Stream<ClusterData?> get aggregatedClusterDataStream;

  /// Remove all of the existing Markers and replace them with [markers]. Note
  /// that this requires completely rebuilding the clusters and may be a slow
  /// operation. If you want to add/remove some markers you should use
  /// [SuperclusterMutableLayer] with [SuperclusterMutableControllerImpl] and use
  /// the add/remove functions.
  void replaceAll(List<Marker> markers);

  /// Clear all of the existing Markers.
  void clear();

  /// An Iterable of all Markers in the order that the inner cluster store holds
  /// them. Note that this will throw an exception if the controller is not yet
  /// associated with the layer, check [isAssociated] first.
  Iterable<Marker> all();
}

abstract class SuperclusterMutableController
    extends SuperclusterControllerBase {
  factory SuperclusterMutableController() =>
      SuperclusterMutableControllerImpl();

  /// Indicates whether this controller is associated with the
  /// SuperlclusterMutableLayer.
  bool get isAssociated;

  /// An Stream of the aggregated cluster data of all points. Note that this
  /// will only be calculated if the stream is being listened to.
  Stream<ClusterData?> get aggregatedClusterDataStream;

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
  Iterable<Marker> all();
}
