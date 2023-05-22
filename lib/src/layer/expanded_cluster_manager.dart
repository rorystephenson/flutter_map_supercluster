import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/splay/cluster_splay_delegate.dart';
import 'package:flutter_map_supercluster/src/splay/displaced_marker.dart';
import 'package:flutter_map_supercluster/src/widget/expanded_cluster.dart';
import 'package:supercluster/supercluster.dart';

class ExpandedClusterManager {
  final Map<String, ExpandedCluster> _expandedClusters = {};
  final void Function(List<ExpandedCluster> expandedClusters) onRemoveStart;
  final void Function(List<ExpandedCluster> expandedClusters) onRemoved;

  ExpandedClusterManager({
    required this.onRemoveStart,
    required this.onRemoved,
  });

  bool contains(LayerCluster<Marker> layerCluster) =>
      _expandedClusters.containsKey(layerCluster.uuid);

  Iterable<ExpandedCluster> get all => _expandedClusters.values;

  Iterable<DisplacedMarker> get displacedMarkers =>
      _expandedClusters.values.expand((e) => e.displacedMarkers);

  void add({
    required TickerProvider vsync,
    required FlutterMapState mapState,
    required Supercluster<Marker> supercluster,
    required LayerCluster<Marker> layerCluster,
    required ClusterSplayDelegate clusterSplayDelegate,
    required double expansionZoom,
  }) {
    _expandedClusters[layerCluster.uuid] = ExpandedCluster(
      vsync: vsync,
      mapState: mapState,
      clusterSplayDelegate: clusterSplayDelegate,
      expansionZoom: expansionZoom,
      layerCluster: layerCluster,
      layerPoints: _layerPoints(supercluster, layerCluster),
    );
  }

  void collapseThenRemove(LayerCluster<Marker> layerCluster) {
    final expandedCluster = _expandedClusters[layerCluster.uuid];
    if (expandedCluster == null) return;

    // Will collapse if collapsing has not already been initiated.
    expandedCluster.tryCollapse((collapseTicker) {
      onRemoveStart([expandedCluster]);
      collapseTicker.then((_) {
        _expandedClusters.remove(layerCluster.uuid);
        expandedCluster.dispose();
        onRemoved([expandedCluster]);
      });
    });
  }

  void collapseThenRemoveAll() {
    final layerClustersCopy = List.from(
      _expandedClusters.values.map((e) => e.layerCluster),
    );

    for (final layerCluster in layerClustersCopy) {
      collapseThenRemove(layerCluster);
    }
  }

  void removeIfZoomGreaterThan(int zoom) {
    final immediateRemovals = <ExpandedCluster>[];

    _expandedClusters.removeWhere((uuid, expandedCluster) {
      if (expandedCluster.layerCluster.lowestZoom > zoom) {
        immediateRemovals.add(expandedCluster);
        expandedCluster.dispose();
        return true;
      } else if (expandedCluster.layerCluster.highestZoom != zoom) {
        collapseThenRemove(expandedCluster.layerCluster);
      }
      return false;
    });

    if (immediateRemovals.isNotEmpty) {
      onRemoveStart(immediateRemovals);
      onRemoved(immediateRemovals);
    }
  }

  /// Removes all without triggering onRemove callback.
  void clear() {
    for (final expandedCluster in _expandedClusters.values) {
      expandedCluster.dispose();
    }
    _expandedClusters.clear();
  }

  List<LayerPoint<Marker>> _layerPoints(
    Supercluster<Marker> supercluster,
    LayerCluster<Marker> layerCluster,
  ) {
    if (supercluster is SuperclusterImmutable<Marker>) {
      return supercluster
          .childrenOf((layerCluster as ImmutableLayerCluster<Marker>).id)
          .cast<ImmutableLayerPoint<Marker>>()
          .toList();
    } else if (supercluster is SuperclusterMutable<Marker>) {
      return supercluster
          .childrenOf((layerCluster as MutableLayerCluster<Marker>))
          .cast<MutableLayerPoint<Marker>>()
          .toList();
    } else {
      throw 'Unexpected supercluster type: ${supercluster.runtimeType}';
    }
  }
}
