import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_fast_cluster/flutter_map_fast_cluster.dart';
import 'package:flutter_map_fast_cluster/src/map_calculator.dart';

import 'cluster_data.dart';

class ClusterWidget extends StatelessWidget {
  final LayerCluster<Marker> cluster;
  final ClusterWidgetBuilder builder;
  final VoidCallback onTap;
  final Size size;
  final Point<double> position;

  ClusterWidget({
    Key? key,
    required MapCalculator mapCalculator,
    required this.cluster,
    required this.builder,
    required this.onTap,
    required this.size,
  })  : position = _getClusterPixel(mapCalculator, cluster),
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
        child: builder(context, clusterData.markerCount, clusterData.innerData),
      ),
    );
  }

  static Point<double> _getClusterPixel(
    MapCalculator mapCalculator,
    LayerCluster<Marker> cluster,
  ) {
    final pos =
        mapCalculator.getPixelFromPoint(mapCalculator.clusterPoint(cluster));

    return mapCalculator.removeClusterAnchor(pos, cluster);
  }
}
