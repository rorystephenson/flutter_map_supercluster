import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/layer/cluster_data.dart';
import 'package:flutter_map_supercluster/src/layer/flutter_map_state_extension.dart';
import 'package:flutter_map_supercluster/src/layer/supercluster_layer.dart';
import 'package:flutter_map_supercluster/src/layer_element_extension.dart';
import 'package:flutter_map_supercluster/src/splay/cluster_splay_delegate.dart';
import 'package:flutter_map_supercluster/src/splay/displaced_marker.dart';
import 'package:flutter_map_supercluster/src/splay/displaced_marker_offset.dart';
import 'package:supercluster/supercluster.dart';

class ExpandedCluster {
  final LayerCluster<Marker> layerCluster;
  final ClusterData clusterData;
  final double expansionZoom;
  final List<DisplacedMarker> displacedMarkers;
  final Size maxMarkerSize;
  final ClusterSplayDelegate clusterSplayDelegate;

  final AnimationController animation;
  late final CurvedAnimation _splayAnimation;
  late final CurvedAnimation _clusterOpacityAnimation;

  ExpandedCluster({
    required TickerProvider vsync,
    required this.layerCluster,
    required this.expansionZoom,
    required FlutterMapState mapState,
    required List<LayerPoint<Marker>> layerPoints,
    required this.clusterSplayDelegate,
  })  : clusterData = layerCluster.clusterData as ClusterData,
        animation = AnimationController(
          vsync: vsync,
          duration: clusterSplayDelegate.duration,
        )..forward(),
        displacedMarkers = clusterSplayDelegate.displaceMarkers(
          layerPoints.map((e) => e.originalPoint).toList(),
          clusterPosition: layerCluster.latLng,
          project: (latLng) => mapState.project(latLng, expansionZoom),
          unproject: (point) => mapState.unproject(point, expansionZoom),
        ),
        maxMarkerSize = layerPoints.fold(
          Size.zero,
          (previous, layerPoint) => Size(
            max(previous.width, layerPoint.originalPoint.width),
            max(previous.height, layerPoint.originalPoint.height),
          ),
        ) {
    _splayAnimation = CurvedAnimation(
      parent: animation,
      curve: clusterSplayDelegate.curve,
    );
    _clusterOpacityAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(0.2, 1.0, curve: clusterSplayDelegate.curve),
    );
  }

  List<DisplacedMarkerOffset> displacedMarkerOffsets(
    FlutterMapState mapState,
    CustomPoint clusterPosition,
  ) =>
      clusterSplayDelegate.displacedMarkerOffsets(
        displacedMarkers,
        animation.value,
        mapState.getPixelOffset,
        clusterPosition,
      );

  Widget? splayDecoration(List<DisplacedMarkerOffset> displacedMarkerOffsets) =>
      clusterSplayDelegate.splayDecoration(displacedMarkerOffsets);

  Widget buildCluster(
    BuildContext context,
    ClusterWidgetBuilder clusterBuilder,
  ) =>
      clusterSplayDelegate.buildCluster(
        context,
        clusterBuilder,
        layerCluster.latLng,
        clusterData.markerCount,
        clusterData.innerData,
        animation.value,
      );

  double get splay => _splayAnimation.value;

  double get splayDistance => clusterSplayDelegate.distance;

  bool get isExpanded => animation.status == AnimationStatus.completed;

  bool get collapsing =>
      animation.isAnimating && animation.status == AnimationStatus.reverse;

  void tryCollapse(void Function(TickerFuture collapseTicker) onCollapse) {
    if (!collapsing) onCollapse(animation.reverse());
  }

  void dispose() {
    _splayAnimation.dispose();
    _clusterOpacityAnimation.dispose();
    animation.dispose();
  }
}
