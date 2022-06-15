import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_fast_cluster/flutter_map_fast_cluster.dart';

abstract class ClusterManager {
  List<ClusterOrMapPoint<Marker>> getClustersAndPointsIn(
      LatLngBounds bounds, int zoom);

  double getClusterExpansionZoom(Cluster<Marker> cluster);

  Widget? buildRotatedOverlay(
      BuildContext context, MapCalculator mapCalculator);

  Widget? buildNonRotatedOverlay(
      BuildContext context, MapCalculator mapCalculator);
}
