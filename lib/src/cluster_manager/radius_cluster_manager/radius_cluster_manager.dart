import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_fast_cluster/flutter_map_fast_cluster.dart';
import 'package:flutter_map_fast_cluster/src/cluster_manager/radius_cluster_manager/search_circle_painter.dart';
import 'package:latlong2/latlong.dart';

import '../../cluster_layer_controller.dart';

/// TODO:
/// Have a customisable function which (async) gets clusters/points within
///    a radius.
/// * Don't show button if the viewport is within the circle.
/// *... then run a mini server which serves up the pre-generated
class RadiusClusterManager extends ClusterManager {
  static const _distanceCalculator =
      Distance(roundResult: false, calculator: Haversine());

  final double radiusInKm;
  final ClusterLayerController clusterLayerController;
  final FutureOr<Supercluster<Marker>> Function(LatLng center, double radius)
      search;
  final Size maximumMarkerOrClusterSize;
  final double borderWidth;
  late final Color borderColor;
  RadiusSearchResult? _radiusSearchResult;
  Supercluster<Marker>? _clustersAndMarkers;

  RadiusClusterManager({
    required this.radiusInKm,
    required this.clusterLayerController,
    required this.search,
    required this.maximumMarkerOrClusterSize,
    this.borderWidth = 3,
    Color? borderColor,
    RadiusSearchResult? initialRadiusSearchResult,
  }) : _radiusSearchResult = initialRadiusSearchResult {
    this.borderColor = Colors.blueAccent.withOpacity(0.4);
  }

  void setCenter(LatLng center) {
    _clustersAndMarkers = null;
    _radiusSearchResult = null;
    clusterLayerController.markersUpdated();
    final searchFuture = search(center, radiusInKm);
    _radiusSearchResult = RadiusSearchResult(
      center: center,
      supercluster: searchFuture,
    );
    Future.sync(() => searchFuture).then((value) {
      _clustersAndMarkers = value;
      clusterLayerController.markersUpdated();
    });
  }

  @override
  List<ClusterOrMapPoint<Marker>> getClustersAndPointsIn(
      LatLngBounds bounds, int zoom) {
    if (_clustersAndMarkers == null) return [];

    return _clustersAndMarkers!.getClustersAndPoints(
      bounds.west,
      bounds.south,
      bounds.east,
      bounds.north,
      zoom,
    );
  }

  @override
  double getClusterExpansionZoom(Cluster<Marker> cluster) {
    if (_clustersAndMarkers == null) throw 'No clusters loaded';

    return _clustersAndMarkers!.getClusterExpansionZoom(cluster.id).toDouble();
  }

  @override
  Widget? buildRotatedOverlay(
      BuildContext context, MapCalculator mapCalculator) {
    return _circleOverlay(mapCalculator);
  }

  @override
  Widget? buildNonRotatedOverlay(
      BuildContext context, MapCalculator mapCalculator) {
    return _loadingButton(mapCalculator);
  }

  Widget? _circleOverlay(MapCalculator mapCalculator) {
    if (_radiusSearchResult == null) return null;

    final centerLatLng = _radiusSearchResult!.center;
    final circlePixel = mapCalculator.getPixelFromPoint(centerLatLng);

    final rightEdgeLatLng =
        _distanceCalculator.offset(centerLatLng, radiusInKm * 1000, 90);
    final rightEdgePixel = mapCalculator.getPixelFromPoint(rightEdgeLatLng);
    final pixelRadius = rightEdgePixel.x - circlePixel.x;

    return LayoutBuilder(
      builder: (context, constraints) => CustomPaint(
        painter: SearchCirclePainter(
          pixelRadius: pixelRadius.toDouble(),
          offset: Offset(
            circlePixel.x.toDouble(),
            circlePixel.y.toDouble(),
          ),
          borderColor: borderColor,
          borderWidth: 10,
        ),
        size: constraints.biggest,
      ),
    );
  }

  Widget _loadingButton(MapCalculator mapCalculator) {
    final mapState = mapCalculator.mapState;
    final mapCenter = mapState.center;
    return Align(
      alignment: Alignment.bottomCenter,
      child: FutureBuilder<Supercluster<Marker>?>(
        key: ObjectKey(_radiusSearchResult?.center),
        future: Future.sync(() => _radiusSearchResult?.supercluster),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ElevatedButton(
              child: const Text('Load crags'),
              onPressed: () {
                setCenter(mapCenter);
              },
            );
          } else if (snapshot.hasError) {
            return ElevatedButton(
              child: const Text('Retry'),
              onPressed: () {
                setCenter(mapCenter);
              },
            );
          } else {
            return ElevatedButton(
              onPressed: null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const Text('Loading'),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class RadiusSearchResult {
  final LatLng center;
  final FutureOr<Supercluster<Marker>> supercluster;

  RadiusSearchResult({
    required this.center,
    required this.supercluster,
  });
}
