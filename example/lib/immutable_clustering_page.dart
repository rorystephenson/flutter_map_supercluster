import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_map_supercluster_example/drawer.dart';
import 'package:latlong2/latlong.dart';

class ClusteringManyMarkersPage extends StatefulWidget {
  static const String route = 'clusteringManyMarkersPage';

  const ClusteringManyMarkersPage({Key? key}) : super(key: key);

  @override
  State<ClusteringManyMarkersPage> createState() =>
      _ClusteringManyMarkersPageState();
}

class _ClusteringManyMarkersPageState extends State<ClusteringManyMarkersPage>
    with TickerProviderStateMixin {
  static const totalMarkers = 2000.0;
  final minLatLng = const LatLng(49.8566, 1.3522);
  final maxLatLng = const LatLng(58.3498, -10.2603);

  late final SuperclusterImmutableController _superclusterController;
  late final AnimatedMapController _animatedMapController;

  late final List<Marker> markers;

  @override
  void initState() {
    _superclusterController = SuperclusterImmutableController();
    _animatedMapController = AnimatedMapController(vsync: this);

    final latitudeRange = maxLatLng.latitude - minLatLng.latitude;
    final longitudeRange = maxLatLng.longitude - minLatLng.longitude;

    final stepsInEachDirection = sqrt(totalMarkers).floor();
    final latStep = latitudeRange / stepsInEachDirection;
    final lonStep = longitudeRange / stepsInEachDirection;

    markers = [];
    for (var i = 0; i < stepsInEachDirection; i++) {
      for (var j = 0; j < stepsInEachDirection; j++) {
        final latLng = LatLng(
          minLatLng.latitude + i * latStep,
          minLatLng.longitude + j * lonStep,
        );

        markers.add(
          Marker(
            anchorPos: AnchorPos.align(AnchorAlign.top),
            rotateAlignment: AnchorAlign.top.rotationAlignment,
            height: 30,
            width: 30,
            point: latLng,
            builder: (ctx) => const Icon(Icons.pin_drop),
          ),
        );
      }
    }

    super.initState();
  }

  @override
  void dispose() {
    _superclusterController.dispose();
    _animatedMapController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SuperclusterScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Clustering Many Markers Page'),
          actions: [
            Builder(builder: (context) {
              final data = SuperclusterState.of(context);
              final String markerCountLabel;
              if (data.loading || data.aggregatedClusterData == null) {
                markerCountLabel = '...';
              } else {
                markerCountLabel =
                    data.aggregatedClusterData!.markerCount.toString();
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text('Total:\n$markerCountLabel'),
                ),
              );
            }),
          ],
        ),
        drawer: buildDrawer(context, ClusteringManyMarkersPage.route),
        body: FlutterMap(
          mapController: _animatedMapController.mapController,
          options: MapOptions(
            center: LatLng((maxLatLng.latitude + minLatLng.latitude) / 2,
                (maxLatLng.longitude + minLatLng.longitude) / 2),
            zoom: 6,
            maxZoom: 15,
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            SuperclusterLayer.immutable(
              initialMarkers: markers,
              indexBuilder: IndexBuilders.computeWithOriginalMarkers,
              controller: _superclusterController,
              moveMap: (center, zoom) => _animatedMapController.animateTo(
                dest: center,
                zoom: zoom,
              ),
              calculateAggregatedClusterData: true,
              clusterWidgetSize: const Size(40, 40),
              anchor: AnchorPos.align(AnchorAlign.center),
              popupOptions: PopupOptions(
                selectedMarkerBuilder: (context, marker) => const Icon(
                  Icons.pin_drop,
                  color: Colors.red,
                ),
                popupDisplayOptions: PopupDisplayOptions(
                  builder: (BuildContext context, Marker marker) => Container(
                    color: Colors.white,
                    child: Text(marker.point.toString()),
                  ),
                ),
              ),
              builder: (context, position, markerCount, extraClusterData) {
                return Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Colors.blue),
                  child: Center(
                    child: Text(
                      markerCount.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
