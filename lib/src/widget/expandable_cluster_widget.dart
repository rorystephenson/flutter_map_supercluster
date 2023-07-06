import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_supercluster/src/layer/map_camera_extension.dart';
import 'package:flutter_map_supercluster/src/layer_element_extension.dart';
import 'package:flutter_map_supercluster/src/splay/popup_spec_builder.dart';
import 'package:flutter_map_supercluster/src/widget/cluster_widget.dart';
import 'package:flutter_map_supercluster/src/widget/expanded_cluster.dart';
import 'package:flutter_map_supercluster/src/widget/marker_widget.dart';

import '../layer/supercluster_layer.dart';

class ExpandableClusterWidget extends StatelessWidget {
  final MapCamera mapCamera;
  final ExpandedCluster expandedCluster;
  final ClusterWidgetBuilder builder;
  final Size size;
  final AnchorPos? anchorPos;
  final Widget Function(BuildContext, Marker) markerBuilder;
  final void Function(PopupSpec popupSpec) onMarkerTap;
  final VoidCallback onCollapse;
  final CustomPoint clusterPixelPosition;

  ExpandableClusterWidget({
    Key? key,
    required this.mapCamera,
    required this.expandedCluster,
    required this.builder,
    required this.size,
    required this.anchorPos,
    required this.markerBuilder,
    required this.onMarkerTap,
    required this.onCollapse,
  })  : clusterPixelPosition =
            mapCamera.getPixelOffset(expandedCluster.layerCluster.latLng),
        super(key: ValueKey('expandable-${expandedCluster.layerCluster.uuid}'));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: expandedCluster.animation,
      builder: (context, _) {
        final displacedMarkerOffsets = expandedCluster.displacedMarkerOffsets(
          mapCamera,
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
                (offset) => MarkerWidget.displaced(
                  displacedMarker: offset.displacedMarker,
                  position: clusterPixelPosition + offset.displacedOffset,
                  markerBuilder: (context) => markerBuilder(
                    context,
                    offset.displacedMarker.marker,
                  ),
                  onTap: () => onMarkerTap(
                    PopupSpecBuilder.forDisplacedMarker(
                      offset.displacedMarker,
                      expandedCluster.minimumVisibleZoom,
                    ),
                  ),
                  mapRotationRad: mapCamera.rotationRad,
                ),
              ),
              ClusterWidget(
                mapCamera: mapCamera,
                cluster: expandedCluster.layerCluster,
                builder: (context, latLng, count, data) =>
                    expandedCluster.buildCluster(context, builder),
                onTap: expandedCluster.isExpanded ? onCollapse : () {},
                size: size,
                anchorPos: anchorPos,
              ),
            ],
          ),
        );
      },
    );
  }
}
