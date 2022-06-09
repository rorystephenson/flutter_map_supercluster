import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';

import '../flutter_map_fast_cluster.dart';

class FastClusterLayerWidget extends StatelessWidget {
  final FastClusterLayerOptions options;

  const FastClusterLayerWidget({Key? key, required this.options})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return FastClusterLayer(options, mapState, mapState.onMoved);
  }
}
