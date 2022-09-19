import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/layer/cluster_data.dart';
import 'package:supercluster/supercluster.dart';

import 'marker_event.dart';
import 'supercluster_controller.dart';

abstract class SuperclusterControllerBase {
  final StreamController<MarkerEvent> _markerEventController;

  SuperclusterControllerBase()
      : _markerEventController = StreamController.broadcast();

  Stream<MarkerEvent> get stream => _markerEventController.stream;

  @mustCallSuper
  void dispose() {
    _markerEventController.close();
  }
}

abstract class SuperclusterControllerImplBase<T>
    extends SuperclusterControllerBase {
  final StreamController<ClusterData?> _clusterDataStreamController;

  SuperclusterControllerImplBase()
      : _clusterDataStreamController =
            StreamController<ClusterData?>.broadcast();

  Stream<ClusterData?> get aggregatedClusterDataStream =>
      _clusterDataStreamController.stream;

  void setSupercluster(T? supercluster);

  void addAggregatedClusterData(ClusterData? aggregatedClusterData) {
    _clusterDataStreamController.add(aggregatedClusterData);
  }

  @override
  void dispose() {
    _clusterDataStreamController.close();
    super.dispose();
  }
}

class SuperclusterImmutableControllerImpl
    extends SuperclusterControllerImplBase<Supercluster<Marker>>
    implements SuperclusterImmutableController {
  Supercluster<Marker>? _supercluster;

  @override
  bool get isAssociated => _supercluster != null;

  @override
  void replaceAll(List<Marker> markers) {
    _markerEventController.add(ReplaceAllMarkerEvent(markers));
  }

  @override
  void clear() {
    _markerEventController.add(ReplaceAllMarkerEvent([]));
  }

  @override
  Iterable<Marker> all() {
    if (_supercluster == null) {
      throw 'No Supercluster associated the SuperclusterImmutableController.';
    }

    return _supercluster!.getLeaves();
  }

  @override
  void setSupercluster(Supercluster<Marker>? supercluster) {
    _supercluster = supercluster;
  }
}

class SuperclusterMutableControllerImpl
    extends SuperclusterControllerImplBase<SuperclusterMutable<Marker>>
    implements SuperclusterMutableController {
  Supercluster<Marker>? _supercluster;

  @override
  bool get isAssociated => _supercluster != null;

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

  @override
  void replaceAll(List<Marker> markers) {
    _markerEventController.add(ReplaceAllMarkerEvent(markers));
  }

  @override
  void clear() {
    _markerEventController.add(ReplaceAllMarkerEvent([]));
  }

  @override
  Iterable<Marker> all() {
    if (_supercluster == null) {
      throw 'No Supercluster associated the SuperclusterMutableController.';
    }

    return _supercluster!.getLeaves();
  }

  @override
  void setSupercluster(Supercluster<Marker>? supercluster) {
    _supercluster = supercluster;
  }

  @override
  dispose() {
    _clusterDataStreamController.close();
    return super.dispose();
  }
}
