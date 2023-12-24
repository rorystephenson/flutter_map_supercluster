import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_supercluster/src/layer/supercluster_layer.dart';
import 'package:flutter_map_supercluster/src/splay/displaced_marker.dart';
import 'package:flutter_map_supercluster/src/widget/expanded_cluster.dart';
import 'package:supercluster/supercluster.dart';

class PopupSpecBuilder {
  static PopupSpec forDisplacedMarker(
    DisplacedMarker displacedMarker,
    int lowestZoom,
  ) =>
      PopupSpec(
        namespace: SuperclusterLayer.popupNamespace,
        marker: displacedMarker.marker,
        markerPointOverride: displacedMarker.displacedPoint,
        markerAlignmentOverride: DisplacedMarker.alignment,
        removeIfZoomLessThan: lowestZoom,
      );

  static List<PopupSpec> buildList({
    required Supercluster<Marker> supercluster,
    required int zoom,
    required int maxZoom,
    required Iterable<Marker> markers,
    required Iterable<ExpandedCluster> expandedClusters,
  }) {
    return markers
        .map((marker) => build(
              supercluster: supercluster,
              zoom: zoom,
              maxZoom: maxZoom,
              marker: marker,
              expandedClusters: expandedClusters,
            ))
        .whereType<PopupSpec>()
        .toList();
  }

  static PopupSpec? build({
    required Supercluster<Marker> supercluster,
    required int zoom,
    required int maxZoom,
    required Marker marker,
    required Iterable<ExpandedCluster> expandedClusters,
  }) {
    final layerPoint = supercluster.layerPointOf(marker);

    if (layerPoint == null) return null;

    if (layerPoint.lowestZoom > maxZoom) {
      return _matchingDisplacedMarkerPopupSpec(
        layerPoint.originalPoint,
        expandedClusters,
      );
    } else {
      if (layerPoint.lowestZoom > zoom) return null;
      return forLayerPoint(layerPoint);
    }
  }

  static PopupSpec? _matchingDisplacedMarkerPopupSpec(
    Marker marker,
    Iterable<ExpandedCluster> expandedClusters,
  ) {
    for (final expandedCluster in expandedClusters) {
      final matchingDisplacedMarker =
          expandedCluster.markersToDisplacedMarkers[marker];
      if (matchingDisplacedMarker != null) {
        return forDisplacedMarker(
          matchingDisplacedMarker,
          expandedCluster.layerCluster.highestZoom,
        );
      }
    }

    return null;
  }

  static PopupSpec forLayerPoint(LayerPoint<Marker> layerPoint) => PopupSpec(
        namespace: SuperclusterLayer.popupNamespace,
        marker: layerPoint.originalPoint,
        removeIfZoomLessThan: layerPoint.lowestZoom,
      );
}
