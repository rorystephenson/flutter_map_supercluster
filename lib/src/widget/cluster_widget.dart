import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/layer/anchor_util.dart';
import 'package:flutter_map_supercluster/src/layer/flutter_map_state_extension.dart';
import 'package:flutter_map_supercluster/src/layer_element_extension.dart';
import 'package:supercluster/supercluster.dart';

import '../layer/cluster_data.dart';
import '../layer/supercluster_layer.dart';

class ClusterWidget extends StatelessWidget {
  final LayerCluster<Marker> cluster;
  final ClusterWidgetBuilder builder;
  final VoidCallback onTap;
  final Size size;
  final Point<double> position;

  ClusterWidget({
    Key? key,
    required FlutterMapState mapState,
    required this.cluster,
    required this.builder,
    required this.onTap,
    required this.size,
    required AnchorPos? anchorPos,
  })  : position = _getClusterPixel(
          mapState,
          cluster,
          anchorPos,
          size,
        ),
        super(key: ValueKey(cluster.uuid));

  @override
  Widget build(BuildContext context) {
    final clusterData = cluster.clusterData as ClusterData;

    return Positioned(
      width: size.width,
      height: size.height,
      left: position.x,
      top: position.y,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: builder(
          context,
          cluster.latLng,
          clusterData.markerCount,
          clusterData.innerData,
        ),
      ),
    );
  }

  static Point<double> _getClusterPixel(
    FlutterMapState mapState,
    LayerCluster<Marker> cluster,
    AnchorPos? anchorPos,
    Size size,
  ) {
    return AnchorUtil.removeClusterAnchor(
      mapState.getPixelOffset(cluster.latLng),
      cluster,
      anchorPos,
      size,
    );
  }
}
