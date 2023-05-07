import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/layer/flutter_map_state_extension.dart';
import 'package:flutter_map_supercluster/src/layer_element_extension.dart';
import 'package:flutter_map_supercluster/src/widget/cluster_widget.dart';
import 'package:flutter_map_supercluster/src/widget/expanded_cluster.dart';
import 'package:flutter_map_supercluster/src/widget/marker_widget.dart';
import 'package:flutter_map_supercluster/src/widget/rotate.dart';

import '../layer/supercluster_layer.dart';

class ExpandableClusterWidget extends StatelessWidget {
  final FlutterMapState mapState;
  final ExpandedCluster expandedCluster;
  final ClusterWidgetBuilder builder;
  final Size size;
  final AnchorPos? anchorPos;
  final double? rotateAngle;
  final Widget Function(BuildContext, Marker) markerBuilder;
  final void Function(Marker layerPoint) onMarkerTap;
  final VoidCallback onCollapse;
  final Rotate? Function(Marker) markerRotate;
  final CustomPoint clusterPixelPosition;

  ExpandableClusterWidget({
    Key? key,
    required this.mapState,
    required this.expandedCluster,
    required this.builder,
    required this.size,
    required this.anchorPos,
    required this.markerBuilder,
    required this.rotateAngle,
    required this.onMarkerTap,
    required this.onCollapse,
    required this.markerRotate,
  })  : clusterPixelPosition =
            mapState.getPixelOffset(expandedCluster.layerCluster.latLng),
        super(key: ValueKey('expandable-${expandedCluster.layerCluster.uuid}'));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: expandedCluster.animation,
      builder: (context, _) {
        final displacedMarkerOffsets = expandedCluster.displacedMarkerOffsets(
          mapState,
          clusterPixelPosition,
        );
        final splayDecoration = expandedCluster.splayDecoration(
          displacedMarkerOffsets,
        );

        return Positioned.fill(
          child: Stack(
            children: [
              if (splayDecoration != null)
                Positioned(
                  left: clusterPixelPosition.x - expandedCluster.splayDistance,
                  top: clusterPixelPosition.y - expandedCluster.splayDistance,
                  width: expandedCluster.splayDistance * 2,
                  height: expandedCluster.splayDistance * 2,
                  child: splayDecoration,
                ),
              ...displacedMarkerOffsets.map(
                (offset) => MarkerWidget.withPosition(
                  marker: offset.displacedMarker,
                  position: clusterPixelPosition + offset.displacedOffset,
                  markerBuilder: (context) => markerBuilder(
                    context,
                    offset.displacedMarker,
                  ),
                  onTap: () => onMarkerTap(offset.displacedMarker),
                  rotate: markerRotate(offset.displacedMarker),
                ),
              ),
              ClusterWidget(
                mapState: mapState,
                cluster: expandedCluster.layerCluster,
                builder: (context, latLng, count, data) =>
                    expandedCluster.buildCluster(context, builder),
                onTap: expandedCluster.isExpanded ? onCollapse : () {},
                size: size,
                anchorPos: anchorPos,
                rotateAngle: rotateAngle,
              ),
            ],
          ),
        );
      },
    );
  }
}
