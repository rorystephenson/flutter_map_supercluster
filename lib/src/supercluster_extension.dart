import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/controller/marker_matcher.dart';
import 'package:supercluster/supercluster.dart';

extension SuperclusterExtension on Supercluster<Marker> {
  List<LayerPoint<Marker>> layerClusterChildren(
    LayerCluster<Marker> layerCluster,
  ) {
    final thisSupercluster = this;
    if (thisSupercluster is SuperclusterImmutable<Marker>) {
      return thisSupercluster
          .childrenOf((layerCluster as ImmutableLayerCluster<Marker>).id)
          .cast<ImmutableLayerPoint<Marker>>()
          .toList();
    } else if (thisSupercluster is SuperclusterMutable<Marker>) {
      return thisSupercluster
          .childrenOf((layerCluster as MutableLayerCluster<Marker>))
          .cast<MutableLayerPoint<Marker>>()
          .toList();
    } else {
      throw 'Unexpected supercluster type: ${thisSupercluster.runtimeType}';
    }
  }

  LayerPoint<Marker>? layerPointMatching(MarkerMatcher markerMatcher) {
    final latLng = markerMatcher.point;

    final matchingElements = search(
      latLng.longitude - 0.0000000001,
      latLng.latitude - 0.0000000001,
      latLng.longitude + 0.0000000001,
      latLng.latitude + 0.0000000001,
      maxZoom + 1,
    ).where(
      (element) => element.handle(
        cluster: (_) => false,
        point: (point) => markerMatcher.matches(point.originalPoint),
      ),
    );

    return matchingElements.isEmpty
        ? null
        : matchingElements.first as LayerPoint<Marker>;
  }
}
