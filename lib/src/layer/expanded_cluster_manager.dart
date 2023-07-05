import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
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

  ExpandedCluster? forLayerCluster(LayerCluster<Marker> layerCluster) =>
      _expandedClusters[layerCluster.uuid];

  Iterable<ExpandedCluster> get all => _expandedClusters.values;

  // Two scenarios are possible:
  //   1. No matching ExpandedCluster exists. A new one is created, its
  //      animation is started and the TickerFuture is returned.
  //   2. A matching ExpandedCluster exists. If it has finished expanding null
  //      is returned. Otherwise the animation is set to forward and the
  //      TickerFuture is returned.
  TickerFuture? putIfAbsent(
    LayerCluster<Marker> layerCluster,
    ExpandedCluster Function() ifAbsent,
  ) {
    final existing = _expandedClusters[layerCluster.uuid];

    if (existing == null) {
      final expandedCluster = ifAbsent();
      _expandedClusters[layerCluster.uuid] = expandedCluster;
      assert(expandedCluster.layerCluster == layerCluster);
      return expandedCluster.animation.forward();
    } else {
      switch (existing.animation.status) {
        case AnimationStatus.dismissed:
        case AnimationStatus.forward:
        case AnimationStatus.reverse:
          return existing.animation.forward();
        case AnimationStatus.completed:
          return null;
      }
    }
  }

  void collapseThenRemove(LayerCluster<Marker> layerCluster) {
    final expandedCluster = _expandedClusters[layerCluster.uuid];
    if (expandedCluster == null) return;

    // Will collapse if collapsing has not already been initiated.
    expandedCluster.tryCollapse((collapseTicker) {
      onRemoveStart([expandedCluster]);
      collapseTicker.then((_) {
        _expandedClusters.remove(layerCluster.uuid);
        // Dispose after removal so that ExpandedClusterManager never contains
        // disposed ExpandedClusters.
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
    final removed = <ExpandedCluster>[];

    _expandedClusters.removeWhere((uuid, expandedCluster) {
      if (expandedCluster.layerCluster.lowestZoom > zoom) {
        removed.add(expandedCluster);
        return true;
      } else if (expandedCluster.layerCluster.highestZoom != zoom) {
        collapseThenRemove(expandedCluster.layerCluster);
      }
      return false;
    });

    // Dispose after removal so that ExpandedClusterManager never contains
    // disposed ExpandedClusters.
    for (var expandedCluster in removed) {
      expandedCluster.dispose();
    }

    if (removed.isNotEmpty) {
      onRemoveStart(removed);
      onRemoved(removed);
    }
  }

  void removeImmediately(ExpandedCluster expandedCluster) {
    final removed = _expandedClusters.remove(expandedCluster.layerCluster.uuid);
    if (removed == null) return;

    // Dispose after removal so that ExpandedClusterManager never contains
    // disposed ExpandedClusters.
    expandedCluster.dispose();

    onRemoveStart([removed]);
    onRemoved([removed]);
  }

  void removeAllImmediately(Iterable<ExpandedCluster> expandedClusters) {
    final removalIds = expandedClusters.map((e) => e.layerCluster.uuid).toSet();
    final removed = <ExpandedCluster>[];

    _expandedClusters.removeWhere((uuid, expandedCluster) {
      if (removalIds.contains(uuid)) {
        removed.add(expandedCluster);
        return true;
      }
      return false;
    });

    // Dispose after removal so that ExpandedClusterManager never contains
    // disposed ExpandedClusters.
    for (var expandedCluster in removed) {
      expandedCluster.dispose();
    }

    if (removed.isNotEmpty) {
      onRemoveStart(removed);
      onRemoved(removed);
    }
  }

  /// Removes all without triggering onRemove callback. The removal callback is
  /// used for hiding popups but this method should only be called after
  /// re-initializing the supercluster which already hides popups.
  void clear() {
    final removed = List.from(_expandedClusters.values);
    _expandedClusters.clear();

    // Dispose after removal so that ExpandedClusterManager never contains
    // disposed ExpandedClusters.
    for (final expandedCluster in removed) {
      expandedCluster.dispose();
    }
  }
}
